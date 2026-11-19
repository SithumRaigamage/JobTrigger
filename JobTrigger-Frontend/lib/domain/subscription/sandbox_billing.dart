/// Development-only store controls. Implemented by the sandbox billing
/// client and exposed to the Subscription screen; a release build never has
/// an implementation, so the controls never render.
abstract class SandboxBilling {
  /// Stop the renewal. Pro stays until the period ends, like a store cancel.
  Future<void> cancelSubscription();

  /// Resume (or start again) after a cancellation or an expiry.
  Future<void> resubscribe();

  /// Move the period end into the past, to see Free's limits at once.
  Future<void> expireNow();
}
