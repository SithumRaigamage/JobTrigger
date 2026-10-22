import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/github_credentials_repository.dart';
import 'package:job_trigger/presentation/features/settings/github_credentials_notifier.dart';

class _FakeGitHubCredentialsRepository implements GitHubCredentialsRepository {
  Result<List<GitHubCredential>, AppFailure> fetchAllResult = const Ok([]);
  int fetchAllCallCount = 0;

  @override
  Future<Result<List<GitHubCredential>, AppFailure>> fetchAll() async {
    fetchAllCallCount++;
    return fetchAllResult;
  }

  @override
  Future<Result<GitHubCredential, AppFailure>> add({
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  }) => throw UnimplementedError();

  @override
  Future<Result<GitHubCredential, AppFailure>> update(
    String id, {
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  }) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> delete(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<GitHubCredential, AppFailure>> switchActive(String id) =>
      throw UnimplementedError();
}

GitHubCredential _credential(String id, {bool isDefault = false}) =>
    GitHubCredential(
      id: id,
      label: 'Credential $id',
      secret: 'ghp_$id',
      isDefault: isDefault,
    );

void main() {
  test('fetches and exposes the credential list on success', () async {
    final repo = _FakeGitHubCredentialsRepository()
      ..fetchAllResult = Ok([_credential('a'), _credential('b')]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [gitHubCredentialsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final credentials = await container.read(
      gitHubCredentialsNotifierProvider.future,
    );

    expect(credentials.map((credential) => credential.id), ['a', 'b']);
  });

  test('an empty repository response surfaces as an empty list', () async {
    final repo = _FakeGitHubCredentialsRepository()
      ..fetchAllResult = const Ok([]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [gitHubCredentialsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final credentials = await container.read(
      gitHubCredentialsNotifierProvider.future,
    );

    expect(credentials, isEmpty);
  });

  test(
    'a repository failure surfaces as an AsyncError with the AppFailure',
    () async {
      final repo = _FakeGitHubCredentialsRepository()
        ..fetchAllResult = const Err(NetworkFailure());
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          gitHubCredentialsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(gitHubCredentialsNotifierProvider, (_, _) {});

      await expectLater(
        container.read(gitHubCredentialsNotifierProvider.future),
        throwsA(isA<NetworkFailure>()),
      );

      final state = container.read(gitHubCredentialsNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkFailure>());
    },
  );

  test('refresh() re-fetches the credential list', () async {
    final repo = _FakeGitHubCredentialsRepository()
      ..fetchAllResult = Ok([_credential('a')]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [gitHubCredentialsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(gitHubCredentialsNotifierProvider, (_, _) {});
    await container.read(gitHubCredentialsNotifierProvider.future);

    repo.fetchAllResult = Ok([_credential('a'), _credential('b')]);
    await container.read(gitHubCredentialsNotifierProvider.notifier).refresh();
    final credentials = await container.read(
      gitHubCredentialsNotifierProvider.future,
    );

    expect(repo.fetchAllCallCount, 2);
    expect(credentials.map((credential) => credential.id), ['a', 'b']);
  });
}
