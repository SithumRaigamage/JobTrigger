/// P20-75: the app's part of the analytics event catalogue
/// (`docs/subscription/04-email-and-analytics.md` §4.1). Only these events
/// can be sent; a name is never built from user input.
///
/// Data rule: tool names, plan names and limit names only. Never an
/// email, account id, server URL, job or repository name, or a token.
enum AnalyticsEvent {
  appOpen('app_open'),
  toolSelected('tool_selected'),
  serverAdded('server_added'),
  buildTriggered('build_triggered'),
  limitHit('limit_hit'),
  paywallView('paywall_view'),
  purchaseStarted('purchase_started'),
  purchaseCompleted('purchase_completed'),
  purchaseCancelled('purchase_cancelled'),
  restore('restore');

  const AnalyticsEvent(this.wireName);

  /// The name Umami stores, shared with the website and the backend.
  final String wireName;
}
