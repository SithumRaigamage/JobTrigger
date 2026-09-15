import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/domain/github/github_repository.dart';
import 'package:job_trigger/domain/github/github_workflow.dart';
import 'package:job_trigger/presentation/features/github/github_repos_notifier.dart';

class _FakeGitHubRepository implements GitHubRepository {
  Result<List<GitHubRepo>, AppFailure> fetchReposResult = const Ok([]);
  int fetchReposCallCount = 0;

  @override
  Future<Result<List<GitHubRepo>, AppFailure>> fetchRepos() async {
    fetchReposCallCount++;
    return fetchReposResult;
  }

  @override
  Future<Result<List<GitHubWorkflow>, AppFailure>> fetchWorkflows(
    String owner,
    String repo,
  ) => throw UnimplementedError();
}

GitHubRepo _repo(String owner, String name) => GitHubRepo(
  id: '$owner/$name'.hashCode,
  name: name,
  owner: owner,
  fullName: '$owner/$name',
);

void main() {
  test('fetches and exposes the repo list on success', () async {
    final repo = _FakeGitHubRepository()
      ..fetchReposResult = Ok([_repo('octocat', 'hello-world')]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [gitHubRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final repos = await container.read(gitHubReposNotifierProvider.future);

    expect(repos.map((r) => r.fullName), ['octocat/hello-world']);
  });

  test('an empty repository response surfaces as an empty list', () async {
    final repo = _FakeGitHubRepository()..fetchReposResult = const Ok([]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [gitHubRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final repos = await container.read(gitHubReposNotifierProvider.future);

    expect(repos, isEmpty);
  });

  test('a repository failure surfaces as an AsyncError with the AppFailure', () async {
    final repo = _FakeGitHubRepository()
      ..fetchReposResult = const Err(RateLimitFailure());
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [gitHubRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(gitHubReposNotifierProvider, (_, _) {});

    await expectLater(
      container.read(gitHubReposNotifierProvider.future),
      throwsA(isA<RateLimitFailure>()),
    );

    final state = container.read(gitHubReposNotifierProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<RateLimitFailure>());
  });

  test('refresh() re-fetches the repo list', () async {
    final repo = _FakeGitHubRepository()
      ..fetchReposResult = Ok([_repo('octocat', 'hello-world')]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [gitHubRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(gitHubReposNotifierProvider, (_, _) {});
    await container.read(gitHubReposNotifierProvider.future);

    repo.fetchReposResult = Ok([
      _repo('octocat', 'hello-world'),
      _repo('octocat', 'spoon-knife'),
    ]);
    await container.read(gitHubReposNotifierProvider.notifier).refresh();
    final repos = await container.read(gitHubReposNotifierProvider.future);

    expect(repo.fetchReposCallCount, 2);
    expect(repos.map((r) => r.fullName), [
      'octocat/hello-world',
      'octocat/spoon-knife',
    ]);
  });
}
