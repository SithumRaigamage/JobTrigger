// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_safety_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(serverSafetyStore)
final serverSafetyStoreProvider = ServerSafetyStoreProvider._();

final class ServerSafetyStoreProvider
    extends
        $FunctionalProvider<
          ServerSafetyStore,
          ServerSafetyStore,
          ServerSafetyStore
        >
    with $Provider<ServerSafetyStore> {
  ServerSafetyStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverSafetyStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverSafetyStoreHash();

  @$internal
  @override
  $ProviderElement<ServerSafetyStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ServerSafetyStore create(Ref ref) {
    return serverSafetyStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerSafetyStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerSafetyStore>(value),
    );
  }
}

String _$serverSafetyStoreHash() => r'a0b50e897647a55eaf0dbc2882d6edfb414f224f';

/// The state screens watch for read-only/protected flags. Follows the
/// synchronous-build pattern from `AppLockNotifier`: state starts empty and
/// is filled from storage in the background, so widgets can `ref.watch` it
/// without handling an `AsyncValue`.

@ProviderFor(ServerSafetyNotifier)
final serverSafetyNotifierProvider = ServerSafetyNotifierProvider._();

/// The state screens watch for read-only/protected flags. Follows the
/// synchronous-build pattern from `AppLockNotifier`: state starts empty and
/// is filled from storage in the background, so widgets can `ref.watch` it
/// without handling an `AsyncValue`.
final class ServerSafetyNotifierProvider
    extends $NotifierProvider<ServerSafetyNotifier, ServerSafety> {
  /// The state screens watch for read-only/protected flags. Follows the
  /// synchronous-build pattern from `AppLockNotifier`: state starts empty and
  /// is filled from storage in the background, so widgets can `ref.watch` it
  /// without handling an `AsyncValue`.
  ServerSafetyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverSafetyNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverSafetyNotifierHash();

  @$internal
  @override
  ServerSafetyNotifier create() => ServerSafetyNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerSafety value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerSafety>(value),
    );
  }
}

String _$serverSafetyNotifierHash() =>
    r'a9eaea1789fc1863c8b0208ddb778777ddf09dac';

/// The state screens watch for read-only/protected flags. Follows the
/// synchronous-build pattern from `AppLockNotifier`: state starts empty and
/// is filled from storage in the background, so widgets can `ref.watch` it
/// without handling an `AsyncValue`.

abstract class _$ServerSafetyNotifier extends $Notifier<ServerSafety> {
  ServerSafety build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ServerSafety, ServerSafety>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ServerSafety, ServerSafety>,
              ServerSafety,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
