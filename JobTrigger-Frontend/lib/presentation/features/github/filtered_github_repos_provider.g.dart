// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filtered_github_repos_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The repos `GitHubRepoScreen` should actually display — filtered by
/// name/[GitHubRepo.fullName] (so searching "octocat/" narrows to one
/// owner). No folder/breadcrumb concept here unlike `filteredJobs`:
/// GitHub's repo list is flat, not a tree.

@ProviderFor(filteredGitHubRepos)
final filteredGitHubReposProvider = FilteredGitHubReposProvider._();

/// The repos `GitHubRepoScreen` should actually display — filtered by
/// name/[GitHubRepo.fullName] (so searching "octocat/" narrows to one
/// owner). No folder/breadcrumb concept here unlike `filteredJobs`:
/// GitHub's repo list is flat, not a tree.

final class FilteredGitHubReposProvider
    extends
        $FunctionalProvider<
          List<GitHubRepo>,
          List<GitHubRepo>,
          List<GitHubRepo>
        >
    with $Provider<List<GitHubRepo>> {
  /// The repos `GitHubRepoScreen` should actually display — filtered by
  /// name/[GitHubRepo.fullName] (so searching "octocat/" narrows to one
  /// owner). No folder/breadcrumb concept here unlike `filteredJobs`:
  /// GitHub's repo list is flat, not a tree.
  FilteredGitHubReposProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredGitHubReposProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredGitHubReposHash();

  @$internal
  @override
  $ProviderElement<List<GitHubRepo>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<GitHubRepo> create(Ref ref) {
    return filteredGitHubRepos(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<GitHubRepo> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<GitHubRepo>>(value),
    );
  }
}

String _$filteredGitHubReposHash() =>
    r'90eafd57320b52de54bbc31cf89de86309996ab2';
