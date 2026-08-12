import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/app_info_repository_impl.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.statusCode, this.body);

  final int statusCode;
  final dynamic body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

// Real shape confirmed live against lab-trigger-backend (P6-02).
Map<String, dynamic> _appInfoJson() => {
  '_id': 'a1',
  'appVersion': '1.0.0',
  'buildNumber': '1',
  'privacyPolicyUrl': 'https://example.com/privacy',
  'termsOfServiceUrl': 'https://example.com/terms',
  'supportEmail': 'support@jobtrigger.com',
  'openSourceLicensesUrl': 'https://example.com/licenses',
  'createdAt': '2026-08-12T08:12:00.190Z',
  'updatedAt': '2026-08-12T08:12:00.190Z',
  '__v': 0,
};

void main() {
  test('fetchAppInfo maps the JSON body to an AppInfo entity', () async {
    final adapter = _JsonAdapter(200, _appInfoJson());
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final repo = AppInfoRepositoryImpl(dio);

    final result = await repo.fetchAppInfo();

    expect(result, isA<Ok<AppInfo, AppFailure>>());
    final info = (result as Ok<AppInfo, AppFailure>).value;
    expect(info.appVersion, '1.0.0');
    expect(info.buildNumber, '1');
    expect(info.supportEmail, 'support@jobtrigger.com');
  });

  test(
    'fetchAppInfo returns NotFoundFailure when no AppInfo doc exists yet',
    () async {
      // Real backend shape for the empty-singleton case, confirmed live.
      final adapter = _JsonAdapter(404, {
        'message': 'App information not found',
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final repo = AppInfoRepositoryImpl(dio);

      final result = await repo.fetchAppInfo();

      expect(result, isA<Err<AppInfo, AppFailure>>());
      expect(
        (result as Err<AppInfo, AppFailure>).error,
        isA<NotFoundFailure>(),
      );
    },
  );
}
