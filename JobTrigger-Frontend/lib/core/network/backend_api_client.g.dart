// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backend_api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dioBackend)
final dioBackendProvider = DioBackendProvider._();

final class DioBackendProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  DioBackendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioBackendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioBackendHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dioBackend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioBackendHash() => r'290197e1b06562299744d706ecc5a178f123ddbf';
