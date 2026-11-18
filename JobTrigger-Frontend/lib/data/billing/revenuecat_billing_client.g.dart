// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revenuecat_billing_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The client for this build: the preview client when the dev-only
/// `BILLING_PREVIEW` flag is set, RevenueCat when the build has a key for
/// the running platform, otherwise [NoBillingClient].

@ProviderFor(billingClient)
final billingClientProvider = BillingClientProvider._();

/// The client for this build: the preview client when the dev-only
/// `BILLING_PREVIEW` flag is set, RevenueCat when the build has a key for
/// the running platform, otherwise [NoBillingClient].

final class BillingClientProvider
    extends $FunctionalProvider<BillingClient, BillingClient, BillingClient>
    with $Provider<BillingClient> {
  /// The client for this build: the preview client when the dev-only
  /// `BILLING_PREVIEW` flag is set, RevenueCat when the build has a key for
  /// the running platform, otherwise [NoBillingClient].
  BillingClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingClientHash();

  @$internal
  @override
  $ProviderElement<BillingClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BillingClient create(Ref ref) {
    return billingClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillingClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillingClient>(value),
    );
  }
}

String _$billingClientHash() => r'b27b142344078d6a4a746b719e91cc9fa8fc3fc5';
