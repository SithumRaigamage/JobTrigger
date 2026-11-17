import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/billing/revenuecat_billing_client.dart';
import '../../../data/demo/demo_mode_notifier.dart';
import 'entitlements_notifier.dart';

part 'billing_availability.g.dart';

/// P20-23/24: whether this build and account show any subscription UI.
/// False (so the paywall, the Subscription screen and the Profile row are
/// all unreachable) unless the build has a purchase SDK key for this
/// platform **and** the backend has billing switched on **and** the app is
/// not in demo mode. This is how a default build, with no keys or with
/// `BILLING_ENABLED` off, behaves exactly as before subscriptions.
@Riverpod(keepAlive: true)
bool billingAvailable(Ref ref) {
  if (ref.watch(demoModeNotifierProvider)) return false;
  if (!ref.watch(billingClientProvider).isConfigured) return false;
  return ref.watch(entitlementsProvider).billingEnabled;
}
