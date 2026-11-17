/// P20-21: one thing the store sells, store-agnostic. The price is the
/// store's own localised string; the app never builds one itself.
enum BillingPeriod { monthly, yearly }

class BillingOffer {
  const BillingOffer({
    required this.id,
    required this.period,
    required this.priceText,
    this.trialDays,
  });

  /// Opaque to the UI; the billing client maps it back to its package.
  final String id;
  final BillingPeriod period;

  /// e.g. "LKR 1,200.00", exactly as the store formats it.
  final String priceText;

  /// Length of the free trial, in days, when the user is eligible.
  final int? trialDays;
}
