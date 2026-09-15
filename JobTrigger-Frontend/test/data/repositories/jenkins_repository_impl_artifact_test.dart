import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';

/// Echoes back the request path as bytes, so tests can assert on the
/// constructed URL without a real server; a non-2xx `statusCode` lets a
/// test simulate a failure instead.
class _EchoPathAdapter implements HttpClientAdapter {
  _EchoPathAdapter({this.statusCode = 200});

  final int statusCode;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromBytes(options.path.codeUnits, statusCode);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('JenkinsRepositoryImpl.fetchArtifactBytes (US-PIPE-07)', () {
    test(
      'GETs {buildUrl}artifact/{relativePath} and returns the bytes',
      () async {
        final adapter = _EchoPathAdapter();
        final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
          ..httpClientAdapter = adapter;
        final repo = JenkinsRepositoryImpl(dio);

        final result = await repo.fetchArtifactBytes(
          'https://jenkins.test/job/demo/12',
          'build/app.apk',
        );

        expect(
          adapter.lastRequest?.path,
          'https://jenkins.test/job/demo/12/artifact/build/app.apk',
        );
        expect(result, isA<Ok<Uint8List, dynamic>>());
        expect(
          String.fromCharCodes((result as Ok<Uint8List, dynamic>).value),
          'https://jenkins.test/job/demo/12/artifact/build/app.apk',
        );
      },
    );

    test(
      'percent-encodes each path segment, preserving / as a separator',
      () async {
        final adapter = _EchoPathAdapter();
        final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
          ..httpClientAdapter = adapter;
        final repo = JenkinsRepositoryImpl(dio);

        await repo.fetchArtifactBytes(
          'https://jenkins.test/job/demo/12',
          'build output/my app.apk',
        );

        expect(
          adapter.lastRequest?.path,
          'https://jenkins.test/job/demo/12/artifact/build%20output/my%20app.apk',
        );
      },
    );

    test('maps a non-2xx response to Err', () async {
      final adapter = _EchoPathAdapter(statusCode: 404);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchArtifactBytes(
        'https://jenkins.test/job/demo/12',
        'build/app.apk',
      );

      expect(result, isA<Err<Uint8List, dynamic>>());
    });
  });
}
