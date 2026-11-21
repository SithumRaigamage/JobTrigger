import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/credentials/active_github_credential_notifier.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/data/credentials/default_choice_sync.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/github_credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/sonarqube_credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/github_credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/credential/sonarqube_credentials_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owner decision 2026-11-21 (US-CRED-05, US-GH-CRED-03, US-SQ-CRED-03,
/// US-WEB-18): the phone's choice is also the backend default; a failed
/// switch stays on the phone and is retried; with nothing pending the
/// backend default is followed.
JenkinsServer _server(String id, {bool isDefault = false}) => JenkinsServer(
  id: id,
  serverName: 'Server $id',
  jenkinsURL: 'https://$id.test',
  username: 'u',
  secret: 'fixture-secret',
  isDefault: isDefault,
);

class _Jenkins implements CredentialsRepository {
  _Jenkins(this.defaultId);

  /// Which server the backend calls default.
  String? defaultId;
  bool failSwitch = false;
  final switches = <String>[];

  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async => Ok([
    for (final id in ['a', 'b', 'c']) _server(id, isDefault: id == defaultId),
  ]);

  @override
  Future<Result<JenkinsServer, AppFailure>> switchActive(String id) async {
    switches.add(id);
    if (failSwitch) return const Err(NetworkFailure());
    defaultId = id;
    return Ok(_server(id, isDefault: true));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<ProviderContainer> _start(_Jenkins repo) async {
  final c = ProviderContainer(
    retry: (_, _) => null,
    overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  c.listen(credentialsNotifierProvider, (_, _) {});
  c.listen(activeServerNotifierProvider, (_, _) {});
  await _settle();
  return c;
}

String? _active(ProviderContainer c) =>
    c.read(activeServerNotifierProvider)?.id;

Future<void> _reload(ProviderContainer c) async {
  await c.read(credentialsNotifierProvider.notifier).refresh();
  await _settle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('switching applies at once and makes it the backend default', () async {
    final repo = _Jenkins('a');
    final c = await _start(repo);
    expect(_active(c), 'a');

    await c
        .read(activeServerNotifierProvider.notifier)
        .setActiveServer(_server('b'));
    expect(_active(c), 'b');
    await _settle();

    expect(repo.switches, ['b']);
    expect(repo.defaultId, 'b');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('active_server_pending_default'), isNull);
  });

  test('a failed switch keeps the choice and is retried on reload', () async {
    final repo = _Jenkins('a')..failSwitch = true;
    final c = await _start(repo);

    await c
        .read(activeServerNotifierProvider.notifier)
        .setActiveServer(_server('b'));
    await _settle();
    expect(_active(c), 'b');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('active_server_pending_default'), 'b');

    // The backend still says "a"; a reload must not take the choice back.
    await _reload(c);
    expect(_active(c), 'b');
    // Retried (a repeat is harmless: the switch is idempotent).
    expect(repo.switches.length, greaterThan(1));
    expect(repo.switches.toSet(), {'b'});

    repo.failSwitch = false;
    await _reload(c);
    expect(repo.defaultId, 'b');
    expect(prefs.getString('active_server_pending_default'), isNull);
    expect(_active(c), 'b');
  });

  test(
    'with nothing pending, a default chosen elsewhere is followed',
    () async {
      final repo = _Jenkins('a');
      final c = await _start(repo);
      expect(_active(c), 'a');

      repo.defaultId = 'c'; // e.g. "Make active" on the website
      await _reload(c);

      expect(_active(c), 'c');
      expect(repo.switches, isEmpty);
    },
  );

  test('cold start: pending, then backend default, then this phone, then '
      'first', () {
    final items = [_server('a'), _server('b', isDefault: true), _server('c')];
    String? pick({String? pending, String? saved, List<JenkinsServer>? from}) =>
        pickActive(
          from ?? items,
          idOf: (s) => s.id,
          isDefault: (s) => s.isDefault,
          pendingId: pending,
          savedId: saved,
        )?.id;

    expect(pick(pending: 'c', saved: 'a'), 'c');
    expect(pick(saved: 'a'), 'b');
    expect(pick(saved: 'c', from: [_server('a'), _server('c')]), 'c');
    expect(pick(from: [_server('a'), _server('c')]), 'a');
    expect(pick(pending: 'gone', saved: 'a'), 'b');
  });

  test('a cold start with no backend default pushes the pick', () async {
    final repo = _Jenkins(null);
    final c = await _start(repo);

    expect(_active(c), 'a');
    expect(repo.switches, ['a']);
    expect(repo.defaultId, 'a');
  });

  test('GitHub and SonarQube switches also reach the backend', () async {
    final gh = _GitHub();
    final sq = _Sonar();
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        gitHubCredentialsRepositoryProvider.overrideWithValue(gh),
        sonarQubeCredentialsRepositoryProvider.overrideWithValue(sq),
      ],
    );
    addTearDown(c.dispose);
    c.listen(activeGitHubCredentialNotifierProvider, (_, _) {});
    c.listen(activeSonarQubeCredentialNotifierProvider, (_, _) {});
    await _settle();

    await c
        .read(activeGitHubCredentialNotifierProvider.notifier)
        .setActiveCredential(_GitHub.b);
    await c
        .read(activeSonarQubeCredentialNotifierProvider.notifier)
        .setActiveCredential(_Sonar.b);
    await _settle();

    expect(gh.switches, ['g2']);
    expect(sq.switches, ['s2']);
  });
}

class _GitHub implements GitHubCredentialsRepository {
  static const a = GitHubCredential(
    id: 'g1',
    label: 'A',
    secret: 'fixture-a',
    isDefault: true,
  );
  static const b = GitHubCredential(id: 'g2', label: 'B', secret: 'fixture-b');
  final switches = <String>[];

  @override
  Future<Result<List<GitHubCredential>, AppFailure>> fetchAll() async =>
      const Ok([a, b]);

  @override
  Future<Result<GitHubCredential, AppFailure>> switchActive(String id) async {
    switches.add(id);
    return const Ok(b);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Sonar implements SonarQubeCredentialsRepository {
  static const a = SonarQubeCredential(
    id: 's1',
    label: 'A',
    baseUrl: 'https://sonarcloud.io',
    secret: 'fixture-a',
    isDefault: true,
  );
  static const b = SonarQubeCredential(
    id: 's2',
    label: 'B',
    baseUrl: 'https://sonar.test',
    secret: 'fixture-b',
  );
  final switches = <String>[];

  @override
  Future<Result<List<SonarQubeCredential>, AppFailure>> fetchAll() async =>
      const Ok([a, b]);

  @override
  Future<Result<SonarQubeCredential, AppFailure>> switchActive(
    String id,
  ) async {
    switches.add(id);
    return const Ok(b);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
