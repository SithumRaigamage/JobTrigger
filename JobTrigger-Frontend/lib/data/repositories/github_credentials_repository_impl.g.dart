// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_credentials_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(githubCredentialsRepository)
final githubCredentialsRepositoryProvider =
    GithubCredentialsRepositoryProvider._();

final class GithubCredentialsRepositoryProvider
    extends
        $FunctionalProvider<
          GitHubCredentialsRepository,
          GitHubCredentialsRepository,
          GitHubCredentialsRepository
        >
    with $Provider<GitHubCredentialsRepository> {
  GithubCredentialsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'githubCredentialsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$githubCredentialsRepositoryHash();

  @$internal
  @override
  $ProviderElement<GitHubCredentialsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GitHubCredentialsRepository create(Ref ref) {
    return githubCredentialsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GitHubCredentialsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GitHubCredentialsRepository>(value),
    );
  }
}

String _$githubCredentialsRepositoryHash() =>
    r'a0ec0d14c9e2db01e88f3f24dee46faadd535708';
