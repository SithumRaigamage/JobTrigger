// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_snapshot_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sonarQubeSnapshotStore)
final sonarQubeSnapshotStoreProvider = SonarQubeSnapshotStoreProvider._();

final class SonarQubeSnapshotStoreProvider
    extends
        $FunctionalProvider<
          SonarQubeSnapshotStore,
          SonarQubeSnapshotStore,
          SonarQubeSnapshotStore
        >
    with $Provider<SonarQubeSnapshotStore> {
  SonarQubeSnapshotStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeSnapshotStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeSnapshotStoreHash();

  @$internal
  @override
  $ProviderElement<SonarQubeSnapshotStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SonarQubeSnapshotStore create(Ref ref) {
    return sonarQubeSnapshotStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SonarQubeSnapshotStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SonarQubeSnapshotStore>(value),
    );
  }
}

String _$sonarQubeSnapshotStoreHash() =>
    r'87b68d99599b033372893d11e0e0a48155023315';
