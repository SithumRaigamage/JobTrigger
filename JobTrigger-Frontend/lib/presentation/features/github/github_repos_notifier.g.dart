// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_repos_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches the active credential's repos (`US-GH-REPO-01`) — the
/// GitHub-side equivalent of `JobTreeNotifier`. `refresh()` backs
/// pull-to-refresh on `GitHubRepoScreen`.

@ProviderFor(GitHubReposNotifier)
final gitHubReposNotifierProvider = GitHubReposNotifierProvider._();

/// Fetches the active credential's repos (`US-GH-REPO-01`) — the
/// GitHub-side equivalent of `JobTreeNotifier`. `refresh()` backs
/// pull-to-refresh on `GitHubRepoScreen`.
final class GitHubReposNotifierProvider
    extends $AsyncNotifierProvider<GitHubReposNotifier, List<GitHubRepo>> {
  /// Fetches the active credential's repos (`US-GH-REPO-01`) — the
  /// GitHub-side equivalent of `JobTreeNotifier`. `refresh()` backs
  /// pull-to-refresh on `GitHubRepoScreen`.
  GitHubReposNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitHubReposNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitHubReposNotifierHash();

  @$internal
  @override
  GitHubReposNotifier create() => GitHubReposNotifier();
}

String _$gitHubReposNotifierHash() =>
    r'9a95710bef6f72acc9533c6be75820cfa1567684';

/// Fetches the active credential's repos (`US-GH-REPO-01`) — the
/// GitHub-side equivalent of `JobTreeNotifier`. `refresh()` backs
/// pull-to-refresh on `GitHubRepoScreen`.

abstract class _$GitHubReposNotifier extends $AsyncNotifier<List<GitHubRepo>> {
  FutureOr<List<GitHubRepo>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<GitHubRepo>>, List<GitHubRepo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<GitHubRepo>>, List<GitHubRepo>>,
              AsyncValue<List<GitHubRepo>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
