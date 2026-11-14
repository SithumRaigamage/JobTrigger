// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_credentials_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gitHubCredentialsRepository)
final gitHubCredentialsRepositoryProvider =
    GitHubCredentialsRepositoryProvider._();

final class GitHubCredentialsRepositoryProvider
    extends
        $FunctionalProvider<
          GitHubCredentialsRepository,
          GitHubCredentialsRepository,
          GitHubCredentialsRepository
        >
    with $Provider<GitHubCredentialsRepository> {
  GitHubCredentialsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitHubCredentialsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitHubCredentialsRepositoryHash();

  @$internal
  @override
  $ProviderElement<GitHubCredentialsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GitHubCredentialsRepository create(Ref ref) {
    return gitHubCredentialsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitHubCredentialsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GitHubCredentialsRepository>(value),
    );
  }
}

String _$gitHubCredentialsRepositoryHash() =>
    r'a8bddb0473fbb9c618eec73fa9b961b17da9b1d1';
