import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/settings/credentials_notifier.dart';

class _FakeCredentialsRepository implements CredentialsRepository {
  Result<List<JenkinsServer>, AppFailure> fetchAllResult = const Ok([]);
  int fetchAllCallCount = 0;

  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async {
    fetchAllCallCount++;
    return fetchAllResult;
  }

  @override
  Future<Result<JenkinsServer, AppFailure>> add({
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) => throw UnimplementedError();

  @override
  Future<Result<JenkinsServer, AppFailure>> update(
    String id, {
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) => throw UnimplementedError();

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
  test('fetches and exposes the server list on success', () async {
    final repo = _FakeCredentialsRepository()
      ..fetchAllResult = Ok([_server('a'), _server('b')]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final servers = await container.read(credentialsNotifierProvider.future);

    expect(servers.map((server) => server.id), ['a', 'b']);
  });

  test('an empty repository response surfaces as an empty list', () async {
    final repo = _FakeCredentialsRepository()..fetchAllResult = const Ok([]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final servers = await container.read(credentialsNotifierProvider.future);

    expect(servers, isEmpty);
  });

  test(
    'a repository failure surfaces as an AsyncError with the AppFailure',
    () async {
      final repo = _FakeCredentialsRepository()
        ..fetchAllResult = const Err(NetworkFailure());
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(credentialsNotifierProvider, (_, _) {});

      await expectLater(
        container.read(credentialsNotifierProvider.future),
        throwsA(isA<NetworkFailure>()),
      );

      final state = container.read(credentialsNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkFailure>());
    },
  );

  test('refresh() re-fetches the server list', () async {
    final repo = _FakeCredentialsRepository()
      ..fetchAllResult = Ok([_server('a')]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(credentialsNotifierProvider, (_, _) {});
    await container.read(credentialsNotifierProvider.future);

    repo.fetchAllResult = Ok([_server('a'), _server('b')]);
    await container.read(credentialsNotifierProvider.notifier).refresh();
    final servers = await container.read(credentialsNotifierProvider.future);

    expect(repo.fetchAllCallCount, 2);
    expect(servers.map((server) => server.id), ['a', 'b']);
  });
}
