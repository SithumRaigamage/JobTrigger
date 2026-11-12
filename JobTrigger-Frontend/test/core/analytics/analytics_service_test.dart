import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/analytics/analytics_event.dart';
import 'package:job_trigger/core/analytics/analytics_service.dart';
import 'package:job_trigger/core/config/app_config.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Records every request and answers [statusCode], or throws when [fail].
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.statusCode = 200, this.fail = false});

  final int statusCode;
  final bool fail;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString('{}', statusCode);
  }

  @override
  void close({bool force = false}) {}
}

UmamiAnalyticsService _service(
  _RecordingAdapter adapter, {
  Future<bool> Function()? isAllowed,
}) => UmamiAnalyticsService(
  dio: Dio(BaseOptions(baseUrl: 'http://umami.test'))
    ..httpClientAdapter = adapter,
  websiteId: 'site-1',
  platform: 'iOS',
  isAllowed: isAllowed ?? () async => true,
);

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test('sends an Umami event with the catalogue name and clean data', () async {
    final adapter = _RecordingAdapter();
    await _service(
      adapter,
    ).track(AnalyticsEvent.toolSelected, {'tool': 'jenkins'});

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.single;
    expect(request.path, '/api/send');
    final body = request.data as Map<String, Object?>;
    expect(body['type'], 'event');
    final payload = body['payload']! as Map<String, Object?>;
    expect(payload['website'], 'site-1');
    expect(payload['name'], 'tool_selected');
    expect(payload['data'], {'platform': 'iOS', 'tool': 'jenkins'});
    // Sanity: the body is plain JSON.
    expect(() => jsonEncode(body), returnsNormally);
  });

  test('sends nothing when the user turned sharing off', () async {
    final adapter = _RecordingAdapter();
    await _service(
      adapter,
      isAllowed: () async => false,
    ).track(AnalyticsEvent.appOpen);
    expect(adapter.requests, isEmpty);
  });

  test('never throws when Umami is down or refuses', () async {
    await _service(_RecordingAdapter(fail: true)).track(AnalyticsEvent.appOpen);
    await _service(
      _RecordingAdapter(statusCode: 500),
    ).track(AnalyticsEvent.appOpen);
  });

  test('keeps only short primitive values under identifier keys', () {
    expect(
      cleanAnalyticsData({
        'ok': 'yes',
        'n': 2,
        'b': true,
        'obj': {'a': 1},
        'long': 'x' * 65,
        'bad key': 1,
        'none': null,
      }),
      {'ok': 'yes', 'n': 2, 'b': true},
    );
    expect(cleanAnalyticsData(null), isNull);
    expect(cleanAnalyticsData({'bad key': 1}), isNull);
  });

  test('uses a browser-like User-Agent so Umami keeps the event', () {
    expect(
      analyticsUserAgent(TargetPlatform.iOS),
      startsWith('Mozilla/5.0'),
    );
  });

  test('the shared preference defaults to sharing', () async {
    // Nothing stored yet: the real consent check allows.
    final adapter = _RecordingAdapter();
    await UmamiAnalyticsService(
      dio: Dio(BaseOptions(baseUrl: 'http://umami.test'))
        ..httpClientAdapter = adapter,
      websiteId: 'w',
      platform: 'android',
    ).track(AnalyticsEvent.appOpen);
    expect(adapter.requests, hasLength(1));
  });

  test('analytics is configured only with both URL and website id', () {
    const off = AppConfig(
      environment: AppEnvironment.dev,
      backendBaseUrl: 'http://127.0.0.1:5001',
    );
    const half = AppConfig(
      environment: AppEnvironment.dev,
      backendBaseUrl: 'http://127.0.0.1:5001',
      umamiUrl: 'http://localhost:3004',
    );
    const on = AppConfig(
      environment: AppEnvironment.dev,
      backendBaseUrl: 'http://127.0.0.1:5001',
      umamiUrl: 'http://localhost:3004',
      umamiWebsiteId: 'w',
    );
    expect(off.analyticsConfigured, isFalse);
    expect(half.analyticsConfigured, isFalse);
    expect(on.analyticsConfigured, isTrue);
  });
}
