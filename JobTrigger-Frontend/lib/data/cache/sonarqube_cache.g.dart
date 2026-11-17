// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sonarQubeCache)
final sonarQubeCacheProvider = SonarQubeCacheProvider._();

final class SonarQubeCacheProvider
    extends $FunctionalProvider<SonarQubeCache, SonarQubeCache, SonarQubeCache>
    with $Provider<SonarQubeCache> {
  SonarQubeCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeCacheHash();

  @$internal
  @override
  $ProviderElement<SonarQubeCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SonarQubeCache create(Ref ref) {
    return sonarQubeCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SonarQubeCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SonarQubeCache>(value),
    );
  }
}

String _$sonarQubeCacheHash() => r'7b9a1957c68ef4054d136de78aa4682bceca498c';
