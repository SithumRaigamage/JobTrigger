import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/domain/github/github_repository.dart';
import 'package:job_trigger/domain/github/github_workflow.dart';
import 'package:job_trigger/presentation/features/github/filtered_github_repos_provider.dart';
import 'package:job_trigger/presentation/features/github/github_repo_search_notifier.dart';
import 'package:job_trigger/presentation/features/github/github_repos_notifier.dart';

class _FakeGitHubRepository implements GitHubRepository {
  _FakeGitHubRepository(this._repos);

  final List<GitHubRepo> _repos;

  @override
  Future<Result<List<GitHubRepo>, AppFailure>> fetchRepos() async =>
      Ok(_repos);

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
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        gitHubRepositoryProvider.overrideWithValue(
          _FakeGitHubRepository([
            _repo('octocat', 'hello-world'),
            _repo('octocat', 'spoon-knife'),
            _repo('other-org', 'widgets'),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test('empty query shows every repo', () async {
    await container.read(gitHubReposNotifierProvider.future);

    expect(
      container
          .read(filteredGitHubReposProvider)
          .map((repo) => repo.fullName)
          .toList(),
      ['octocat/hello-world', 'octocat/spoon-knife', 'other-org/widgets'],
    );
  });

  test('a query narrows by full name, case-insensitively', () async {
    await container.read(gitHubReposNotifierProvider.future);
    container
        .read(gitHubRepoSearchNotifierProvider.notifier)
        .setQuery('OCTOCAT/');

    expect(
      container
          .read(filteredGitHubReposProvider)
          .map((repo) => repo.fullName)
          .toSet(),
      {'octocat/hello-world', 'octocat/spoon-knife'},
    );
  });

  test('a query matching nothing returns an empty list', () async {
    await container.read(gitHubReposNotifierProvider.future);
    container
        .read(gitHubRepoSearchNotifierProvider.notifier)
        .setQuery('nonexistent');

    expect(container.read(filteredGitHubReposProvider), isEmpty);
  });
}
