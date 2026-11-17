// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_watch_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(buildWatchStore)
final buildWatchStoreProvider = BuildWatchStoreProvider._();

final class BuildWatchStoreProvider
    extends
        $FunctionalProvider<BuildWatchStore, BuildWatchStore, BuildWatchStore>
    with $Provider<BuildWatchStore> {
  BuildWatchStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buildWatchStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buildWatchStoreHash();

  @$internal
  @override
  $ProviderElement<BuildWatchStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BuildWatchStore create(Ref ref) {
    return buildWatchStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuildWatchStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuildWatchStore>(value),
    );
  }
}

String _$buildWatchStoreHash() => r'6804929d2031d12a7d43e4ffca8296581a7cfeb5';
