import '../../domain/subscription/billing_offer.dart';

/// P20-20: the purchase SDK behind an interface, so nothing outside
/// `data/billing/` imports it and tests use a fake. Failures are thrown as
/// the types below; `SubscriptionRepositoryImpl` maps them to `AppFailure`.
abstract class BillingClient {
  /// Whether this build can sell anything (it has an SDK key for this
  /// platform). When false every other method is a no-op or empty.
  bool get isConfigured;

  /// Ties store purchases to the JobTrigger account, so the backend's
  /// webhook knows whose subscription changed.
  Future<void> logIn(String userId);

  Future<void> logOut();

  Future<List<BillingOffer>> offerings();

  /// Throws [BillingCancelled] when the user closes the store sheet.
  Future<void> purchase(BillingOffer offer);

  Future<void> restore();
}

/// The user closed the store's purchase sheet.
class BillingCancelled implements Exception {
  const BillingCancelled();
}

/// The store or SDK refused for any other reason. [debugMessage] is for
/// logs, never shown.
class BillingException implements Exception {
  const BillingException([this.debugMessage]);

  final String? debugMessage;

  @override
  String toString() => 'BillingException($debugMessage)';
}

/// Used when the build has no SDK key (billing off): sells nothing.
class NoBillingClient implements BillingClient {
  const NoBillingClient();

  @override
  bool get isConfigured => false;

  @override
  Future<void> logIn(String userId) async {}

  @override
  Future<void> logOut() async {}

  @override
  Future<List<BillingOffer>> offerings() async => const [];

  @override
  Future<void> purchase(BillingOffer offer) =>
      throw const BillingException('Billing is not configured in this build.');

  @override
  Future<void> restore() =>
      throw const BillingException('Billing is not configured in this build.');
}
