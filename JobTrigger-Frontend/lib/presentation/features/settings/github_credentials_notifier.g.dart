// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_credentials_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// List of saved GitHub credentials — mirrors `CredentialsNotifier`'s
/// shape exactly, standard fetch-list notifier per
/// `docs/architecture.md §4`.

@ProviderFor(GitHubCredentialsNotifier)
final gitHubCredentialsNotifierProvider = GitHubCredentialsNotifierProvider._();

/// List of saved GitHub credentials — mirrors `CredentialsNotifier`'s
/// shape exactly, standard fetch-list notifier per
/// `docs/architecture.md §4`.
final class GitHubCredentialsNotifierProvider
    extends
        $AsyncNotifierProvider<
          GitHubCredentialsNotifier,
          List<GitHubCredential>
        > {
  /// List of saved GitHub credentials — mirrors `CredentialsNotifier`'s
  /// shape exactly, standard fetch-list notifier per
  /// `docs/architecture.md §4`.
  GitHubCredentialsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitHubCredentialsNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitHubCredentialsNotifierHash();

  @$internal
  @override
  GitHubCredentialsNotifier create() => GitHubCredentialsNotifier();
}

String _$gitHubCredentialsNotifierHash() =>
    r'dbb5e60fb8eb3e89512e100106d1af86090645a4';

/// List of saved GitHub credentials — mirrors `CredentialsNotifier`'s
/// shape exactly, standard fetch-list notifier per
/// `docs/architecture.md §4`.

abstract class _$GitHubCredentialsNotifier
    extends $AsyncNotifier<List<GitHubCredential>> {
  FutureOr<List<GitHubCredential>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<GitHubCredential>>, List<GitHubCredential>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<GitHubCredential>>,
                List<GitHubCredential>
              >,
              AsyncValue<List<GitHubCredential>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
