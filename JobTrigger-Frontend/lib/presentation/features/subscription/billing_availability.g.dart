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
///
/// P24-04: a dev-only build with `BILLING_PREVIEW` set opts into the
/// preview client, which serves static offers, so the same UI can be seen
/// without keys. Demo mode still wins: it is its own universe. Release
/// builds can never set the flag (`AppConfig.billingPreview`).

@ProviderFor(billingAvailable)
final billingAvailableProvider = BillingAvailableProvider._();

/// P20-23/24: whether this build and account show any subscription UI.
/// False (so the paywall, the Subscription screen and the Profile row are
/// all unreachable) unless the build has a purchase SDK key for this
/// platform **and** the backend has billing switched on **and** the app is
/// not in demo mode. This is how a default build, with no keys or with
/// `BILLING_ENABLED` off, behaves exactly as before subscriptions.
///
/// P24-04: a dev-only build with `BILLING_PREVIEW` set opts into the
/// preview client, which serves static offers, so the same UI can be seen
/// without keys. Demo mode still wins: it is its own universe. Release
/// builds can never set the flag (`AppConfig.billingPreview`).

final class BillingAvailableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// P20-23/24: whether this build and account show any subscription UI.
  /// False (so the paywall, the Subscription screen and the Profile row are
  /// all unreachable) unless the build has a purchase SDK key for this
  /// platform **and** the backend has billing switched on **and** the app is
  /// not in demo mode. This is how a default build, with no keys or with
  /// `BILLING_ENABLED` off, behaves exactly as before subscriptions.
  ///
  /// P24-04: a dev-only build with `BILLING_PREVIEW` set opts into the
  /// preview client, which serves static offers, so the same UI can be seen
  /// without keys. Demo mode still wins: it is its own universe. Release
  /// builds can never set the flag (`AppConfig.billingPreview`).
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

String _$billingAvailableHash() => r'a7730f77ab8da44e1c25cfbea4ce6c286295d6fc';
