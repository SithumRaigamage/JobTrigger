// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demo_sonarqube_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(demoSonarQubeRepository)
final demoSonarQubeRepositoryProvider = DemoSonarQubeRepositoryProvider._();

final class DemoSonarQubeRepositoryProvider
    extends
        $FunctionalProvider<
          DemoSonarQubeRepository,
          DemoSonarQubeRepository,
          DemoSonarQubeRepository
        >
    with $Provider<DemoSonarQubeRepository> {
  DemoSonarQubeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demoSonarQubeRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demoSonarQubeRepositoryHash();

  @$internal
  @override
  $ProviderElement<DemoSonarQubeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DemoSonarQubeRepository create(Ref ref) {
    return demoSonarQubeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DemoSonarQubeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DemoSonarQubeRepository>(value),
    );
  }
}

String _$demoSonarQubeRepositoryHash() =>
    r'bab3658ce34bf80be4ca2d8a040596f2e13c6537';
