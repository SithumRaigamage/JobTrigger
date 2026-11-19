import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../data/billing/revenuecat_billing_client.dart';
import '../../../data/demo/demo_mode_notifier.dart';
import '../../../domain/subscription/sandbox_billing.dart';
import 'entitlements_notifier.dart';

part 'billing_availability.g.dart';

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
@Riverpod(keepAlive: true)
bool billingAvailable(Ref ref) {
  if (ref.watch(demoModeNotifierProvider)) return false;
  final config = ref.watch(appConfigProvider);
  // Development sandbox: the backend must still be enforcing plans, so the
  // purchase/cancel/resubscribe loop is meaningful.
  if (config.billingSandbox) {
    return ref.watch(entitlementsProvider).billingEnabled;
  }
  if (config.billingPreview) return true;
  if (!ref.watch(billingClientProvider).isConfigured) return false;
  return ref.watch(entitlementsProvider).billingEnabled;
}

/// The development-only store controls, or null when this build has no
/// sandbox (every release build, and any dev build without the flag).
@Riverpod(keepAlive: true)
SandboxBilling? sandboxBilling(Ref ref) {
  final client = ref.watch(billingClientProvider);
  return client is SandboxBilling ? client as SandboxBilling : null;
}
