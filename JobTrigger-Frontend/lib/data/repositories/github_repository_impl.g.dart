// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gitHubRepository)
final gitHubRepositoryProvider = GitHubRepositoryProvider._();

final class GitHubRepositoryProvider
    extends
        $FunctionalProvider<
          GitHubRepository,
          GitHubRepository,
          GitHubRepository
        >
    with $Provider<GitHubRepository> {
  GitHubRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitHubRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitHubRepositoryHash();

  @$internal
  @override
  $ProviderElement<GitHubRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GitHubRepository create(Ref ref) {
    return gitHubRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitHubRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GitHubRepository>(value),
    );
  }
}

String _$gitHubRepositoryHash() => r'08c5f1266a3d1475c08d4057b878b6ca6d65ce5b';
