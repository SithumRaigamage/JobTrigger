// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demo_github_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(demoGitHubRepository)
final demoGitHubRepositoryProvider = DemoGitHubRepositoryProvider._();

final class DemoGitHubRepositoryProvider
    extends
        $FunctionalProvider<
          DemoGitHubRepository,
          DemoGitHubRepository,
          DemoGitHubRepository
        >
    with $Provider<DemoGitHubRepository> {
  DemoGitHubRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demoGitHubRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demoGitHubRepositoryHash();

  @$internal
  @override
  $ProviderElement<DemoGitHubRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DemoGitHubRepository create(Ref ref) {
    return demoGitHubRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DemoGitHubRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DemoGitHubRepository>(value),
    );
  }
}

String _$demoGitHubRepositoryHash() =>
    r'75aea1c879f2913cb81e1129836095c297c3d0f0';
