// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_watch_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sonarQubeWatchStore)
final sonarQubeWatchStoreProvider = SonarQubeWatchStoreProvider._();

final class SonarQubeWatchStoreProvider
    extends
        $FunctionalProvider<
          SonarQubeWatchStore,
          SonarQubeWatchStore,
          SonarQubeWatchStore
        >
    with $Provider<SonarQubeWatchStore> {
  SonarQubeWatchStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeWatchStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeWatchStoreHash();

  @$internal
  @override
  $ProviderElement<SonarQubeWatchStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SonarQubeWatchStore create(Ref ref) {
    return sonarQubeWatchStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SonarQubeWatchStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SonarQubeWatchStore>(value),
    );
  }
}

String _$sonarQubeWatchStoreHash() =>
    r'caba476cd680054cebbfae27f86c87ed2f96317d';
