import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/billing/revenuecat_billing_client.dart';
import '../../../data/demo/demo_mode_notifier.dart';
import '../../../domain/auth/auth_state.dart';
import '../auth/auth_notifier.dart';

part 'billing_session.g.dart';

/// P20-22: keeps the purchase SDK's identity in step with the signed-in
/// account (`logIn` with the account id, `logOut` on sign-out), so the
/// backend's webhook can match a purchase to its owner. Does nothing in
/// demo mode or in a build with no SDK key. Watched by
/// `EntitlementsNotifier`; nothing else needs to know it exists.
@Riverpod(keepAlive: true)
void billingSession(Ref ref) {
  final client = ref.watch(billingClientProvider);
  if (!client.isConfigured) return;
  ref.listen(authNotifierProvider, (previous, next) async {
    if (ref.read(demoModeNotifierProvider)) return;
    final auth = next.value;
    try {
      if (auth is Authenticated) {
        await client.logIn(auth.user.id);
      } else if (auth is Unauthenticated) {
        await client.logOut();
      }
    } on Object catch (error, stackTrace) {
      // Purchases are optional; a failed identity call must not break
      // sign-in. Retried on the next auth change.
      developer.log(
        'Billing identity sync failed',
        name: 'billingSession',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }, fireImmediately: true);
}
