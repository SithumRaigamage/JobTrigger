import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/network/host_pinning.dart';
import 'package:job_trigger/data/datasources/jenkins_client_factory.dart';
import 'package:job_trigger/data/datasources/sonarqube_client_factory.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _RecordingAdapter adapter;
  late Dio jenkins;

  setUp(() {
    adapter = _RecordingAdapter();
    jenkins = buildJenkinsDio(
      baseUrl: 'https://a.example.com/jenkins/',
      username: 'alice',
      password: 'secret-a',
    )..httpClientAdapter = adapter;
  });

  // AUD-45: a notification tap once sent server A's Basic Auth to server B.
  test("a Jenkins client never sends a request to another server's host", () {
    expect(
      jenkins.get<dynamic>('https://b.example.com/job/deploy/api/json'),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          isA<ForeignHostRequest>(),
        ),
      ),
    );
    expect(adapter.requests, isEmpty);
  });

  test('a different port or scheme on the same host is also refused', () async {
    for (final url in [
      'https://a.example.com:8443/jenkins/api/json',
      'http://a.example.com/jenkins/api/json',
    ]) {
      await expectLater(
        jenkins.get<dynamic>(url),
        throwsA(isA<DioException>()),
      );
    }
    expect(adapter.requests, isEmpty);
  });

  test('relative and same-host absolute URLs still go through', () async {
    await jenkins.get<dynamic>('/api/json');
    await jenkins.get<dynamic>('https://A.example.com/jenkins/job/x/api/json');
    expect(adapter.requests, hasLength(2));
  });

  test('a SonarQube client is pinned to its own server too', () {
    final adapter = _RecordingAdapter();
    final sonar = buildSonarQubeDio(
      baseUrl: 'https://sonar.example.com',
      token: 't',
    )..httpClientAdapter = adapter;
    expect(
      sonar.get<dynamic>('https://evil.example.com/api/x'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, isEmpty);
  });
}
