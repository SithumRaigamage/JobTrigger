import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/notification_service.dart';
import '../../../domain/subscription/subscription_status.dart';

/// US-PROMO-06: the `shared_preferences` entry holding the promo end a
/// notification was last shown for, so one period is announced once and
/// resuming the app does not repeat it. Removed with the rest of the user's
/// entries on logout (AUD-28, `data/cache/user_scoped_prefs.dart`).
const promoReminderPrefKey = 'promo_expiry_reminded';

/// US-PROMO-06: a fixed notification id, so a later reminder replaces the last
/// one instead of stacking in the notification centre.
const promoReminderNotificationId = 20251;

/// US-PROMO-06: how close to the end the reminder arrives — three days, the
/// lead the owner asked for.
const promoReminderLead = Duration(days: 3);

/// US-PROMO-06: what the notification says: the day Pro ends, and what
/// follows.
String promoReminderBody(DateTime end) =>
    'Pro from your code ends on ${formatPromoDate(end.toLocal())}. When it '
    "ends you're back on the Free plan.";

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

/// A date as the reminder and its banner read it: "3 Jun 2027".
String formatPromoDate(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${d.year}';

/// US-PROMO-06: shows the local notification when [snapshot] is Pro from a
/// redeemed code and that period ends within [lead] (three days), once per
/// period: the end date itself is the marker, so redeeming another code — a
/// new end — is announced again, and the same one never twice.
///
/// The period is marked **only after the OS took the notification**: with
/// notifications not allowed (most people who redeem a code never turned them
/// on) the app leaves it unmarked and says it in-app instead
/// (`PromoExpiryBanner`), and an OS that refused today still gets the
/// reminder once it is allowed. Best effort throughout: no storage or
/// platform-channel failure reaches the caller, and the plan is read from what
/// the app already had, so this never makes a request of its own.
Future<void> remindPromoEndingSoon(
  SubscriptionSnapshot snapshot,
  NotificationService notifications, {
  DateTime? now,
  Duration lead = promoReminderLead,
}) async {
  final end = snapshot.promoEndingSoon(now ?? DateTime.now(), within: lead);
  if (end == null) return;
  final marker = end.toUtc().toIso8601String();
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(promoReminderPrefKey) == marker) return;
    final shown = await notifications.showSubscriptionAlert(
      id: promoReminderNotificationId,
      title: 'Your Pro from a code ends soon',
      body: promoReminderBody(end),
    );
    if (!shown) return;
    await prefs.setString(promoReminderPrefKey, marker);
  } on Object {
    // Best effort: a reminder is never worth an error in the app.
  }
}
