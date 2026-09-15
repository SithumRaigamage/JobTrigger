import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';
import 'package:job_trigger/presentation/features/settings/credentials_notifier.dart';
import 'package:job_trigger/presentation/features/settings/server_form_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _FakeCredentialsRepository implements CredentialsRepository {
  _FakeCredentialsRepository(this._servers);

  final List<JenkinsServer> _servers;
  Result<JenkinsServer, AppFailure>? addResult;
  Result<JenkinsServer, AppFailure>? updateResult;
  String? lastUpdatedId;

  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      Ok(List.of(_servers));

  @override
  Future<Result<JenkinsServer, AppFailure>> add({
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) async {
    final result = addResult!;
    if (result case Ok(:final value)) _servers.add(value);
    return result;
  }

  @override
  Future<Result<JenkinsServer, AppFailure>> update(
    String id, {
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) async {
    lastUpdatedId = id;
    return updateResult!;
  }

  @override
  Future<Result<void, AppFailure>> delete(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<JenkinsServer, AppFailure>> switchActive(String id) =>
      throw UnimplementedError();
}

JenkinsServer _server(String id, {bool isDefault = false}) => JenkinsServer(
  id: id,
  serverName: 'Server $id',
  jenkinsURL: 'https://$id.test',
  username: 'user',
  secret: 'pass',
  isDefault: isDefault,
);

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test('adding a server refreshes the credentials list on success', () async {
    final repo = _FakeCredentialsRepository([])..addResult = Ok(_server('a'));
    final container = ProviderContainer(
      overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(serverFormNotifierProvider, (_, _) {});
    container.listen(credentialsNotifierProvider, (_, _) {});

    await container
        .read(serverFormNotifierProvider.notifier)
        .save(
          serverName: 'Server a',
          jenkinsURL: 'https://a.test',
          username: 'user',
          secret: 'pass',
          isDefault: false,
        );

    expect(container.read(serverFormNotifierProvider).hasError, isFalse);
    final servers = await container.read(credentialsNotifierProvider.future);
    expect(servers.map((server) => server.id), ['a']);
  });

  test('adding a server with isDefault sets it as the active server', () async {
    final repo = _FakeCredentialsRepository([])
      ..addResult = Ok(_server('a', isDefault: true));
    final container = ProviderContainer(
      overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(serverFormNotifierProvider, (_, _) {});
    container.listen(credentialsNotifierProvider, (_, _) {});
    container.listen(activeServerNotifierProvider, (_, _) {});

    await container
        .read(serverFormNotifierProvider.notifier)
        .save(
          serverName: 'Server a',
          jenkinsURL: 'https://a.test',
          username: 'user',
          secret: 'pass',
          isDefault: true,
        );

    expect(container.read(activeServerNotifierProvider)?.id, 'a');
  });

  test('editing a server calls repository.update with the given id', () async {
    final existing = _server('a');
    final repo = _FakeCredentialsRepository([existing])
      ..updateResult = Ok(_server('a'));
    final container = ProviderContainer(
      overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(serverFormNotifierProvider, (_, _) {});
    container.listen(credentialsNotifierProvider, (_, _) {});

    await container
        .read(serverFormNotifierProvider.notifier)
        .save(
          id: 'a',
          serverName: 'Renamed',
          jenkinsURL: 'https://a.test',
          username: 'user',
          secret: 'pass',
          isDefault: false,
        );

    expect(repo.lastUpdatedId, 'a');
    expect(container.read(serverFormNotifierProvider).hasError, isFalse);
  });

  test(
    'a repository failure surfaces as ServerFormNotifier state error',
    () async {
      final repo = _FakeCredentialsRepository([])
        ..addResult = const Err(ServerFailure(500));
      final container = ProviderContainer(
        overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(serverFormNotifierProvider, (_, _) {});

      await container
          .read(serverFormNotifierProvider.notifier)
          .save(
            serverName: 'Server a',
            jenkinsURL: 'https://a.test',
            username: 'user',
            secret: 'pass',
            isDefault: false,
          );

      expect(
        container.read(serverFormNotifierProvider).error,
        isA<AppFailure>(),
      );
    },
  );
}
