import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

part 'analytics_consent_notifier.g.dart';

/// Profile → "Share anonymous usage" (P20-76). Not a secret, so
/// `shared_preferences`, like the theme. [UmamiAnalyticsService] reads the
/// same key at send time, so turning it off stops the very next event.
@riverpod
class AnalyticsConsentNotifier extends _$AnalyticsConsentNotifier {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(shareUsageKey) ?? true;
  }

  Future<void> setAllowed(bool allowed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(shareUsageKey, allowed);
    if (ref.mounted) state = AsyncData(allowed);
  }
}
