import 'billing_client.dart';

import '../../domain/subscription/billing_offer.dart';

/// P24-04: dev-only preview client. Serves the website's two plans as static
/// offers so the Subscription screen, the paywall and the Profile status row
/// render in a build without RevenueCat keys. [isConfigured] is true so
/// `billingAvailable` opens the UI, but no money can move: [purchase] always
/// fails and [restore] always finds nothing, which is what a preview build
/// with no store behind it honestly is.
///
/// Only ever returned when `AppConfig.billingPreview` is set, which no
/// release build can be — the offers are placeholders, the prices are the
/// website's, and the real store's localised strings replace them once keys
/// exist.
class PreviewBillingClient implements BillingClient {
  const PreviewBillingClient();

  // Numbers mirror JobTrigger-Web/src/content/pricing.ts (US-SUB-08).
  static const _monthly = BillingOffer(
    id: 'preview_monthly',
    period: BillingPeriod.monthly,
    priceText: '\$19.99',
  );
  static const _yearly = BillingOffer(
    id: 'preview_yearly',
    period: BillingPeriod.yearly,
    priceText: '\$239.00',
    trialDays: 7,
  );

  @override
  bool get isConfigured => true;

  @override
  Future<void> logIn(String userId) async {}

  @override
  Future<void> logOut() async {}

  @override
  Future<List<BillingOffer>> offerings() async => const [_monthly, _yearly];

  @override
  Future<void> purchase(BillingOffer offer) =>
      throw const BillingException('Preview build: no store is connected');

  @override
  Future<void> restore() async {}
}
