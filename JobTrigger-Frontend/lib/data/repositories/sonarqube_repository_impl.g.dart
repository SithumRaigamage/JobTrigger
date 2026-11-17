// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sonarQubeRepository)
final sonarQubeRepositoryProvider = SonarQubeRepositoryProvider._();

final class SonarQubeRepositoryProvider
    extends
        $FunctionalProvider<
          SonarQubeRepository,
          SonarQubeRepository,
          SonarQubeRepository
        >
    with $Provider<SonarQubeRepository> {
  SonarQubeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeRepositoryHash();

  @$internal
  @override
  $ProviderElement<SonarQubeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SonarQubeRepository create(Ref ref) {
    return sonarQubeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SonarQubeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SonarQubeRepository>(value),
    );
  }
}

String _$sonarQubeRepositoryHash() =>
    r'27e64f3741e34467d1a3b755b6b348ed28023e9d';
