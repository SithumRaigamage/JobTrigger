import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'billing_offer.dart';
import 'subscription_status.dart';

abstract class SubscriptionRepository {
  /// The last good answer kept on this device, or null. Lets the app start
  /// with the right gates offline. Cleared on sign-out.
  Future<SubscriptionSnapshot?> cached();

  /// `GET /api/subscription`.
  Future<Result<SubscriptionSnapshot, AppFailure>> load();

  /// `POST /api/subscription/refresh`: re-reads the store record after a
  /// purchase or restore.
  Future<Result<SubscriptionSnapshot, AppFailure>> refresh();

  /// `POST /api/subscription/promo`: redeems a promo or voucher code
  /// (US-PROMO-01) and returns the plan it granted. A refused code keeps the
  /// backend's own sentence (`StudentRequestFailure`).
  Future<Result<SubscriptionSnapshot, AppFailure>> redeemPromoCode(String code);

  /// What the store sells right now. Empty when billing isn't configured in
  /// this build.
  Future<Result<List<BillingOffer>, AppFailure>> offerings();

  /// Buys [offer]. A user closing the store sheet is
  /// `Err(PurchaseCancelled())`, shown as nothing.
  Future<Result<void, AppFailure>> purchase(BillingOffer offer);

  /// Restores earlier purchases on this store account.
  Future<Result<void, AppFailure>> restore();
}
