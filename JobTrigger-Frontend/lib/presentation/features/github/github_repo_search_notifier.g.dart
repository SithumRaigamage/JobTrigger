// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_repo_search_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GitHubRepoSearchNotifier)
final gitHubRepoSearchNotifierProvider = GitHubRepoSearchNotifierProvider._();

final class GitHubRepoSearchNotifierProvider
    extends $NotifierProvider<GitHubRepoSearchNotifier, String> {
  GitHubRepoSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitHubRepoSearchNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitHubRepoSearchNotifierHash();

  @$internal
  @override
  GitHubRepoSearchNotifier create() => GitHubRepoSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$gitHubRepoSearchNotifierHash() =>
    r'b03d6766325acfa94cbb43c7326f38802707225d';

abstract class _$GitHubRepoSearchNotifier extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
