// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jenkins_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(jenkinsRepository)
final jenkinsRepositoryProvider = JenkinsRepositoryProvider._();

final class JenkinsRepositoryProvider
    extends
        $FunctionalProvider<
          JenkinsRepository,
          JenkinsRepository,
          JenkinsRepository
        >
    with $Provider<JenkinsRepository> {
  JenkinsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jenkinsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jenkinsRepositoryHash();

  @$internal
  @override
  $ProviderElement<JenkinsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JenkinsRepository create(Ref ref) {
    return jenkinsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JenkinsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JenkinsRepository>(value),
    );
  }
}

String _$jenkinsRepositoryHash() => r'd331e6c32396cd7b057450f28d838c64067c08d9';
