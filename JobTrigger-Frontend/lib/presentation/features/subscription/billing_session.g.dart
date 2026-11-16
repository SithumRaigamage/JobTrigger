// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// P20-22: keeps the purchase SDK's identity in step with the signed-in
/// account (`logIn` with the account id, `logOut` on sign-out), so the
/// backend's webhook can match a purchase to its owner. Does nothing in
/// demo mode or in a build with no SDK key. Watched by
/// `EntitlementsNotifier`; nothing else needs to know it exists.

@ProviderFor(billingSession)
final billingSessionProvider = BillingSessionProvider._();

/// P20-22: keeps the purchase SDK's identity in step with the signed-in
/// account (`logIn` with the account id, `logOut` on sign-out), so the
/// backend's webhook can match a purchase to its owner. Does nothing in
/// demo mode or in a build with no SDK key. Watched by
/// `EntitlementsNotifier`; nothing else needs to know it exists.

final class BillingSessionProvider extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// P20-22: keeps the purchase SDK's identity in step with the signed-in
  /// account (`logIn` with the account id, `logOut` on sign-out), so the
  /// backend's webhook can match a purchase to its owner. Does nothing in
  /// demo mode or in a build with no SDK key. Watched by
  /// `EntitlementsNotifier`; nothing else needs to know it exists.
  BillingSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingSessionHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return billingSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$billingSessionHash() => r'c86fc81e489b578fe09550c80571a7836a31b538';
