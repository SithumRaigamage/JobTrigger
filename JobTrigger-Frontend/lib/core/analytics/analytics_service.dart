import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'analytics_event.dart';

part 'analytics_service.g.dart';

/// The `shared_preferences` key behind Profile → "Share anonymous usage"
/// (P20-76). Missing means on: events carry no personal data, and the
/// toggle and the privacy policy say so.
const shareUsageKey = 'share_anonymous_usage';

/// P20-76: anonymous product events. Callers fire and forget — [track]
/// never throws and never waits on the network for the caller's sake.
abstract class AnalyticsService {
  Future<void> track(AnalyticsEvent event, [Map<String, Object?>? data]);
}

/// Used when analytics isn't configured (dev runs without Umami, tests).
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> track(AnalyticsEvent event, [Map<String, Object?>? data]) async {}
}

/// Up to ten entries whose keys are identifiers and whose values are
/// short strings, numbers or booleans — the rest is dropped. Same rules as
/// the backend's `lib/analytics.js`.
@visibleForTesting
Map<String, Object>? cleanAnalyticsData(Map<String, Object?>? data) {
  if (data == null) return null;
  final key = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{0,39}$');
  final out = <String, Object>{};
  for (final MapEntry(key: name, :value) in data.entries.take(10)) {
    if (!key.hasMatch(name)) continue;
    switch (value) {
      case final num n:
        out[name] = n;
      case final bool b:
        out[name] = b;
      case final String s when s.length <= 64:
        out[name] = s;
    }
  }
  return out.isEmpty ? null : out;
}

/// Sends events to a self-hosted Umami (`POST /api/send`) over its own
/// [Dio] — not the backend's, so no JobTrigger token ever goes to Umami,
/// and a slow Umami can't hold up backend calls.
class UmamiAnalyticsService implements AnalyticsService {
  UmamiAnalyticsService({
    required Dio dio,
    required this.websiteId,
    required this.platform,
    Future<bool> Function()? isAllowed,
  }) : _dio = dio,
       _isAllowed = isAllowed ?? _userAllows;

  final Dio _dio;
  final String websiteId;
  final String platform;
  final Future<bool> Function() _isAllowed;

  static Future<bool> _userAllows() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(shareUsageKey) ?? true;
  }

  @override
  Future<void> track(AnalyticsEvent event, [Map<String, Object?>? data]) async {
    try {
      if (!await _isAllowed()) return;
      final cleaned = cleanAnalyticsData({'platform': platform, ...?data});
      await _dio.post<void>(
        '/api/send',
        data: {
          'type': 'event',
          'payload': {
            'website': websiteId,
            'hostname': 'app.jobtrigger.local',
            'url': '/app',
            'name': event.wireName,
            if (cleaned != null) 'data': cleaned,
          },
        },
      );
    } on Object catch (error) {
      // Analytics must never surface to the user or fail a flow.
      debugPrint('analytics: ${event.wireName} not sent ($error)');
    }
  }
}

/// Umami drops requests without a browser-like User-Agent (bot filter).
@visibleForTesting
String analyticsUserAgent(TargetPlatform platform) =>
    'Mozilla/5.0 (${platform.name}; JobTrigger app)';

@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.analyticsConfigured) return const NoopAnalyticsService();
  final dio = Dio(
    BaseOptions(
      baseUrl: config.umamiUrl!,
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
      headers: {'User-Agent': analyticsUserAgent(defaultTargetPlatform)},
    ),
  );
  ref.onDispose(dio.close);
  return UmamiAnalyticsService(
    dio: dio,
    websiteId: config.umamiWebsiteId!,
    platform: defaultTargetPlatform.name,
  );
}
