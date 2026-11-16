import 'entitlements.dart';

/// Mirrors the backend's `Subscription.status`.
enum SubscriptionState {
  none,
  trialing,
  active,
  grace,
  billingIssue,
  cancelled,
  expired,
}

/// Where the subscription was bought (`Subscription.source`).
enum SubscriptionSource { appStore, playStore, web, promo, admin, student }

/// P20-21: the details the Subscription screen shows (US-SUB-01).
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.state,
    this.source,
    this.productId,
    this.periodEnd,
    this.willRenew = false,
    this.manageOnWeb = false,
    this.primaryCredentialId,
  });

  static const none = SubscriptionStatus(state: SubscriptionState.none);

  final SubscriptionState state;
  final SubscriptionSource? source;
  final String? productId;
  final DateTime? periodEnd;
  final bool willRenew;

  /// True when Paddle's portal can manage it (a web subscription): the app
  /// shows it as Pro but never links to web checkout (App Review rules).
  final bool manageOnWeb;

  /// The one server kept usable on Free, if the user chose one.
  final String? primaryCredentialId;

  /// Bought on the website rather than in a store (US-SUB web).
  bool get isWeb => source == SubscriptionSource.web;

  /// Phase 21: the free year for verified students.
  bool get isStudent => source == SubscriptionSource.student;

  /// Bought in the App Store or Google Play.
  bool get isStore =>
      source == SubscriptionSource.appStore ||
      source == SubscriptionSource.playStore;
}

/// The backend's answer: what the user may do, and why.
class SubscriptionSnapshot {
  const SubscriptionSnapshot({
    required this.entitlements,
    required this.status,
  });

  final Entitlements entitlements;
  final SubscriptionStatus status;

  /// A store subscription that will bill again: deleting the account does
  /// not cancel it, so the delete dialog says so (US-SUB-07).
  bool get hasRenewingStoreSubscription =>
      entitlements.billingEnabled &&
      entitlements.isPro &&
      status.isStore &&
      status.willRenew &&
      switch (status.state) {
        SubscriptionState.trialing ||
        SubscriptionState.active ||
        SubscriptionState.grace ||
        SubscriptionState.billingIssue => true,
        _ => false,
      };

  /// Pro that came from the website (P20-84): shown as Pro like any other,
  /// with no store purchase offered.
  bool get isWebPro =>
      entitlements.billingEnabled && entitlements.isPro && status.isWeb;
}
