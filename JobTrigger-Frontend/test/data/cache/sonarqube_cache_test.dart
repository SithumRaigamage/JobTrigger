import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/cache/sonarqube_cache.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_projects_notifier.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_summaries_notifier.dart';

import '../../support/sonarqube_insights_defaults.dart';

const _p = SonarQubeProject(key: 'a', name: 'Alpha', lastAnalysisDate: null);
const _failed = SonarQubeProjectSummary(
  gate: QualityGateState.failed,
  bugs: 3,
  coverage: 61.5,
);

class _Repo with SonarQubeInsightsDefaults implements SonarQubeRepository {
  AppFailure? failure;

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) async => failure != null
      ? Err(failure!)
      : const Ok(SonarQubeProjectsPage(projects: [_p], total: 1));

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) async => failure != null
      ? Err(failure!)
      : Ok({for (final k in projectKeys) k: _failed});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Credential extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => const SonarQubeCredential(
    id: 'c1',
    label: 'L',
    baseUrl: 'http://s',
    secret: 'tok',
  );
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('sq_cache_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test(
    'saves and reads the list and the numbers, and nothing secret',
    () async {
      final cache = SonarQubeCache(() async => dir);
      final at = DateTime(2026, 11, 17, 9);
      await cache.writeProjects('c1', [_p], 1, now: at);
      await cache.mergeSummaries('c1', {'a': _failed});

      final copy = (await cache.read('c1'))!;
      expect(copy.projects.single.name, 'Alpha');
      expect(copy.summaries['a']!.gate, QualityGateState.failed);
      expect(copy.summaries['a']!.bugs, 3);
      expect(copy.summaries['a']!.coverage, 61.5);
      expect(copy.savedAt, at);

      final raw = dir
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.readAsStringSync())
          .join();
      expect(raw, isNot(contains('tok')));
      expect(raw, isNot(contains('http://')));
    },
  );

  test('numbers are only kept beside a saved list, per credential', () async {
    final cache = SonarQubeCache(() async => dir);
    await cache.mergeSummaries('c1', {'a': _failed});
    expect(await cache.read('c1'), isNull);

    await cache.writeProjects('c1', [_p], 1);
    expect(await cache.read('c2'), isNull);
    await cache.clearCredential('c1');
    expect(await cache.read('c1'), isNull);
  });

  test('a corrupt file is no cache, and clearAll removes everything', () async {
    final cache = SonarQubeCache(() async => dir);
    await cache.writeProjects('c1', [_p], 1);
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      f.writeAsStringSync('{not json');
    }
    expect(await cache.read('c1'), isNull);
    await cache.writeProjects('c1', [_p], 1);
    await cache.clearAll();
    expect(await cache.read('c1'), isNull);
  });

  group('offline behaviour (US-SQ-OFFLINE-01)', () {
    // One cache for the whole app, as the real provider is keepAlive.
    late SonarQubeCache shared;
    setUp(() => shared = SonarQubeCache(() async => dir));

    ProviderContainer container(_Repo repo) {
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          activeSonarQubeCredentialNotifierProvider.overrideWith(
            _Credential.new,
          ),
          sonarQubeRepositoryProvider.overrideWithValue(repo),
          sonarQubeCacheProvider.overrideWithValue(shared),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      'no connection shows the saved list and numbers, marked saved',
      () async {
        final repo = _Repo();
        final online = container(repo);
        online.listen(sonarQubeProjectsNotifierProvider, (_, _) {});
        online.listen(sonarQubeSummariesNotifierProvider, (_, _) {});
        final live = await online.read(
          sonarQubeProjectsNotifierProvider.future,
        );
        expect(live.savedAt, isNull);
        await online.read(sonarQubeSummariesNotifierProvider.notifier).ensure([
          'a',
        ]);

        // A new session, now with no connection.
        repo.failure = const NetworkFailure();
        final offline = container(repo);
        offline.listen(sonarQubeProjectsNotifierProvider, (_, _) {});
        offline.listen(sonarQubeSummariesNotifierProvider, (_, _) {});
        final saved = await offline.read(
          sonarQubeProjectsNotifierProvider.future,
        );
        expect(saved.savedAt, isNotNull);
        expect(saved.projects.single.key, 'a');
        expect(saved.hasMore, isFalse);

        await offline.read(sonarQubeSummariesNotifierProvider.notifier).ensure([
          'a',
        ]);
        final numbers = offline.read(sonarQubeSummariesNotifierProvider);
        expect(numbers.byKey['a']!.gate, QualityGateState.failed);
        expect(numbers.failure, isNull);
      },
    );

    test('a refused token is never answered with old data', () async {
      final repo = _Repo();
      final online = container(repo);
      online.listen(sonarQubeProjectsNotifierProvider, (_, _) {});
      await online.read(sonarQubeProjectsNotifierProvider.future);

      repo.failure = const AuthFailure();
      final again = container(repo);
      again.listen(sonarQubeProjectsNotifierProvider, (_, _) {});
      await again
          .read(sonarQubeProjectsNotifierProvider.future)
          .then<void>((_) {}, onError: (Object _) {});
      expect(
        again.read(sonarQubeProjectsNotifierProvider).error,
        isA<AuthFailure>(),
      );
    });

    test('no connection and nothing saved is still the error', () async {
      final repo = _Repo()..failure = const NetworkFailure();
      final c = container(repo);
      c.listen(sonarQubeProjectsNotifierProvider, (_, _) {});
      await c
          .read(sonarQubeProjectsNotifierProvider.future)
          .then<void>((_) {}, onError: (Object _) {});
      expect(
        c.read(sonarQubeProjectsNotifierProvider).error,
        isA<NetworkFailure>(),
      );
    });
  });
}
