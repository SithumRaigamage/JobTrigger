import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';

/// Scripts a single fixed (status, body) response, same shape as
/// `jenkins_repository_impl_trigger_test.dart`'s `_RecordingAdapter`.
class _FixedResponseAdapter implements HttpClientAdapter {
  _FixedResponseAdapter(this.statusCode, [this.body = const {}]);

  final int statusCode;
  final Map<String, dynamic> body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
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

void main() {
  group('JenkinsRepositoryImpl.fetchTestReport (US-PIPE-06)', () {
    test('parses a real test report response', () async {
      final adapter = _FixedResponseAdapter(200, {
        'passCount': 10,
        'failCount': 1,
        'skipCount': 0,
        'suites': [
          {
            'cases': [
              {'className': 'com.example.X', 'name': 'y', 'status': 'FAILED'},
            ],
          },
        ],
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchTestReport(
        'https://jenkins.test/job/demo/12',
      );

      expect(result, isA<Ok<TestReport?, dynamic>>());
      final report = (result as Ok<TestReport?, dynamic>).value;
      expect(report!.passCount, 10);
      expect(report.failCount, 1);
      expect(report.failingTests, ['com.example.X.y']);
      expect(
        adapter.lastRequest?.path,
        'https://jenkins.test/job/demo/12/testReport/api/json',
      );
    });

    test('returns Ok(null) — not an Err — when Jenkins 404s', () async {
      final adapter = _FixedResponseAdapter(404);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchTestReport(
        'https://jenkins.test/job/demo/12',
      );

      expect(result, isA<Ok<TestReport?, dynamic>>());
      expect((result as Ok<TestReport?, dynamic>).value, isNull);
    });

    test('a non-404 failure still maps to Err', () async {
      final adapter = _FixedResponseAdapter(500);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchTestReport(
        'https://jenkins.test/job/demo/12',
      );

      expect(result, isA<Err<dynamic, dynamic>>());
    });
  });
}
