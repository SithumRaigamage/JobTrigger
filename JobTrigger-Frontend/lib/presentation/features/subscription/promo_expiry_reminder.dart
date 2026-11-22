import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform/notification_service.dart';
import '../../../domain/subscription/subscription_status.dart';

/// US-PROMO-06: the `shared_preferences` entry holding the promo end the
/// reminder was last shown for, so one period is reminded about once and
/// resuming the app does not repeat it. Removed with the rest of the user's
/// entries on logout (AUD-28, `data/cache/user_scoped_prefs.dart`).
const promoReminderPrefKey = 'promo_expiry_reminded';

/// US-PROMO-06: a fixed notification id, so a later reminder replaces the last
/// one instead of stacking in the notification centre.
const promoReminderNotificationId = 20251;

/// US-PROMO-06: how close to the end the reminder arrives — three days, the
/// lead the owner asked for.
const promoReminderLead = Duration(days: 3);

/// US-PROMO-06: what the reminder says: the day Pro ends, and what follows.
String promoReminderBody(DateTime end) =>
    'Pro from your code ends on ${_formatDay(end.toLocal())}. When it ends '
    "you're back on the Free plan.";

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

String _formatDay(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// US-PROMO-06: shows the local notification when [snapshot] is Pro from a
/// redeemed code and that period ends within [lead] (three days), once per
/// period: the end date itself is the marker, so redeeming another code — a
/// new end — is reminded about again, and the same one never twice.
///
/// Best effort throughout: no storage or platform-channel failure reaches the
/// caller, and the plan is read from what the app already had, so this never
/// makes a request of its own.
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
    // Recorded before the notification: a failing platform channel must not
    // turn every resume into another attempt.
    await prefs.setString(promoReminderPrefKey, marker);
    await notifications.showSubscriptionAlert(
      id: promoReminderNotificationId,
      title: 'Your Pro from a code ends soon',
      body: promoReminderBody(end),
    );
  } on Object {
    // Best effort: a reminder is never worth an error in the app.
  }
}
