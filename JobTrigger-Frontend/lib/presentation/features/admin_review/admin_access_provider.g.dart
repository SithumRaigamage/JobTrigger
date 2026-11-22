// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_access_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-STU-02: whether the signed-in account may review student
/// applications (role `superAdmin`, asked of the backend, which checks it
/// again on every admin call). False when signed out, in demo mode, for
/// everyone else and on any failure, so the Profile row and the routes stay
/// hidden unless the server said yes. Not tied to billing.

@ProviderFor(adminAccess)
final adminAccessProvider = AdminAccessProvider._();

/// US-STU-02: whether the signed-in account may review student
/// applications (role `superAdmin`, asked of the backend, which checks it
/// again on every admin call). False when signed out, in demo mode, for
/// everyone else and on any failure, so the Profile row and the routes stay
/// hidden unless the server said yes. Not tied to billing.

final class AdminAccessProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// US-STU-02: whether the signed-in account may review student
  /// applications (role `superAdmin`, asked of the backend, which checks it
  /// again on every admin call). False when signed out, in demo mode, for
  /// everyone else and on any failure, so the Profile row and the routes stay
  /// hidden unless the server said yes. Not tied to billing.
  AdminAccessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminAccessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminAccessHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return adminAccess(ref);
  }
}

String _$adminAccessHash() => r'a651be8d1c652634ee68313b72a91127b64376f1';
