// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_availability.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// P20-23/24: whether this build and account show any subscription UI.
/// False (so the paywall, the Subscription screen and the Profile row are
/// all unreachable) unless the build has a purchase SDK key for this
/// platform **and** the backend has billing switched on **and** the app is
/// not in demo mode. This is how a default build, with no keys or with
/// `BILLING_ENABLED` off, behaves exactly as before subscriptions.

@ProviderFor(billingAvailable)
final billingAvailableProvider = BillingAvailableProvider._();

/// P20-23/24: whether this build and account show any subscription UI.
/// False (so the paywall, the Subscription screen and the Profile row are
/// all unreachable) unless the build has a purchase SDK key for this
/// platform **and** the backend has billing switched on **and** the app is
/// not in demo mode. This is how a default build, with no keys or with
/// `BILLING_ENABLED` off, behaves exactly as before subscriptions.

final class BillingAvailableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// P20-23/24: whether this build and account show any subscription UI.
  /// False (so the paywall, the Subscription screen and the Profile row are
  /// all unreachable) unless the build has a purchase SDK key for this
  /// platform **and** the backend has billing switched on **and** the app is
  /// not in demo mode. This is how a default build, with no keys or with
  /// `BILLING_ENABLED` off, behaves exactly as before subscriptions.
  BillingAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingAvailableProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingAvailableHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return billingAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$billingAvailableHash() => r'2bcf53fd41134bc4731616cdeccdcd811bac528c';
