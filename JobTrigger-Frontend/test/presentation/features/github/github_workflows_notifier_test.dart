import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/domain/github/github_repository.dart';
import 'package:job_trigger/domain/github/github_workflow.dart';
import 'package:job_trigger/presentation/features/github/github_workflows_notifier.dart';

const _owner = 'octocat';
const _repoName = 'hello-world';

class _FakeGitHubRepository implements GitHubRepository {
  Result<List<GitHubWorkflow>, AppFailure> fetchWorkflowsResult = const Ok(
    [],
  );
  int fetchWorkflowsCallCount = 0;
  String? lastOwner;
  String? lastRepo;

  @override
  Future<Result<List<GitHubWorkflow>, AppFailure>> fetchWorkflows(
    String owner,
    String repo,
  ) async {
    fetchWorkflowsCallCount++;
    lastOwner = owner;
    lastRepo = repo;
    return fetchWorkflowsResult;
  }

  @override
  Future<Result<List<GitHubRepo>, AppFailure>> fetchRepos() =>
      throw UnimplementedError();
}

GitHubWorkflow _workflow(int id, String name) =>
    GitHubWorkflow(id: id, name: name, path: '.github/workflows/$name.yml', state: 'active');

void main() {
  test(
    'fetches and exposes the workflow list for the given owner/repo on success',
    () async {
      final repo = _FakeGitHubRepository()
        ..fetchWorkflowsResult = Ok([_workflow(1, 'CI')]);
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [gitHubRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final workflows = await container.read(
        gitHubWorkflowsNotifierProvider(_owner, _repoName).future,
      );

      expect(workflows.map((w) => w.name), ['CI']);
      expect(repo.lastOwner, _owner);
      expect(repo.lastRepo, _repoName);
    },
  );

  test('an empty repository response surfaces as an empty list', () async {
    final repo = _FakeGitHubRepository()
      ..fetchWorkflowsResult = const Ok([]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [gitHubRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final workflows = await container.read(
      gitHubWorkflowsNotifierProvider(_owner, _repoName).future,
    );

    expect(workflows, isEmpty);
  });

  test('a repository failure surfaces as an AsyncError with the AppFailure', () async {
    final repo = _FakeGitHubRepository()
      ..fetchWorkflowsResult = const Err(NotFoundFailure());
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [gitHubRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(
      gitHubWorkflowsNotifierProvider(_owner, _repoName),
      (_, _) {},
    );

    await expectLater(
      container.read(gitHubWorkflowsNotifierProvider(_owner, _repoName).future),
      throwsA(isA<NotFoundFailure>()),
    );

    final state = container.read(
      gitHubWorkflowsNotifierProvider(_owner, _repoName),
    );
    expect(state.hasError, isTrue);
    expect(state.error, isA<NotFoundFailure>());
  });

  test('refresh() re-fetches the workflow list', () async {
    final repo = _FakeGitHubRepository()
      ..fetchWorkflowsResult = Ok([_workflow(1, 'CI')]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [gitHubRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(
      gitHubWorkflowsNotifierProvider(_owner, _repoName),
      (_, _) {},
    );
    await container.read(
      gitHubWorkflowsNotifierProvider(_owner, _repoName).future,
    );

    repo.fetchWorkflowsResult = Ok([_workflow(1, 'CI'), _workflow(2, 'Deploy')]);
    await container
        .read(gitHubWorkflowsNotifierProvider(_owner, _repoName).notifier)
        .refresh();
    final workflows = await container.read(
      gitHubWorkflowsNotifierProvider(_owner, _repoName).future,
    );

    expect(repo.fetchWorkflowsCallCount, 2);
    expect(workflows.map((w) => w.name), ['CI', 'Deploy']);
  });
}
