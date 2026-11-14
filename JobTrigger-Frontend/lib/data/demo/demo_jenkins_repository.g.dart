// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demo_jenkins_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One instance per demo session: leaving demo mode disposes it, and with it
/// the scripted run, so the next demo starts from the sample data again.

@ProviderFor(demoJenkinsRepository)
final demoJenkinsRepositoryProvider = DemoJenkinsRepositoryProvider._();

/// One instance per demo session: leaving demo mode disposes it, and with it
/// the scripted run, so the next demo starts from the sample data again.

final class DemoJenkinsRepositoryProvider
    extends
        $FunctionalProvider<
          DemoJenkinsRepository,
          DemoJenkinsRepository,
          DemoJenkinsRepository
        >
    with $Provider<DemoJenkinsRepository> {
  /// One instance per demo session: leaving demo mode disposes it, and with it
  /// the scripted run, so the next demo starts from the sample data again.
  DemoJenkinsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demoJenkinsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demoJenkinsRepositoryHash();

  @$internal
  @override
  $ProviderElement<DemoJenkinsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DemoJenkinsRepository create(Ref ref) {
    return demoJenkinsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DemoJenkinsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DemoJenkinsRepository>(value),
    );
  }
}

String _$demoJenkinsRepositoryHash() =>
    r'87df1cd72c1da40b23146e465f4c9964ba570e45';
