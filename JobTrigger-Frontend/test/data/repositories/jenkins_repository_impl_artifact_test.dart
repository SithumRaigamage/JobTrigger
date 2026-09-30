import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';

/// Answers every request with [body] (the request path when null) and
/// records it, so tests can assert on the constructed URL without a real
/// server; a non-2xx [statusCode] simulates a failure.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.statusCode = 200, this.body, this.contentLength});

  final int statusCode;
  final List<int>? body;
  final int? contentLength;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    final bytes = body ?? options.path.codeUnits;
    return ResponseBody.fromBytes(
      options.method == 'HEAD' ? const [] : bytes,
      statusCode,
      headers: {
        if (contentLength != null)
          Headers.contentLengthHeader: ['$contentLength'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

JenkinsRepositoryImpl _repo(_Adapter adapter) => JenkinsRepositoryImpl(
  Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
    ..httpClientAdapter = adapter,
);

void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync('jt-artifact'));
  tearDown(() => directory.deleteSync(recursive: true));

  group('downloadArtifact (US-PIPE-07, AUD-21)', () {
    test('streams {buildUrl}artifact/{relativePath} to the file', () async {
      final adapter = _Adapter(body: [1, 2, 3, 4], contentLength: 4);
      final path = '${directory.path}/app.apk';
      final progress = <(int, int?)>[];

      final result = await _repo(adapter).downloadArtifact(
        'https://jenkins.test/job/demo/12',
        'build/app.apk',
        path,
        onProgress: (received, total) => progress.add((received, total)),
      );

      expect(result, isA<Ok<void, dynamic>>());
      expect(
        adapter.lastRequest?.path,
        'https://jenkins.test/job/demo/12/artifact/build/app.apk',
      );
      expect(File(path).readAsBytesSync(), [1, 2, 3, 4]);
      expect(progress.last, (4, 4));
    });

    test('an unknown length reports a null total', () async {
      final progress = <(int, int?)>[];
      await _repo(_Adapter(body: [1, 2])).downloadArtifact(
        'https://jenkins.test/job/demo/12',
        'a.bin',
        '${directory.path}/a.bin',
        onProgress: (received, total) => progress.add((received, total)),
      );
      expect(progress.last.$2, isNull);
    });

    test('percent-encodes each path segment, keeping / as a separator', () async {
      final adapter = _Adapter(body: [1]);
      await _repo(adapter).downloadArtifact(
        'https://jenkins.test/job/demo/12',
        'build output/my app.apk',
        '${directory.path}/x',
      );
      expect(
        adapter.lastRequest?.path,
        'https://jenkins.test/job/demo/12/artifact/build%20output/my%20app.apk',
      );
    });

    test('maps a non-2xx response to Err', () async {
      final result = await _repo(_Adapter(statusCode: 404)).downloadArtifact(
        'https://jenkins.test/job/demo/12',
        'build/app.apk',
        '${directory.path}/x',
      );
      expect(result, isA<Err<void, dynamic>>());
    });
  });

  group('fetchArtifactSize (AUD-21)', () {
    test('HEADs the artifact and reads Content-Length', () async {
      final adapter = _Adapter(contentLength: 123456789);
      final result = await _repo(
        adapter,
      ).fetchArtifactSize('https://jenkins.test/job/demo/12', 'build/app.apk');
      expect(adapter.lastRequest?.method, 'HEAD');
      expect((result as Ok<int?, dynamic>).value, 123456789);
    });

    test('is null when the server does not say', () async {
      final result = await _repo(
        _Adapter(),
      ).fetchArtifactSize('https://jenkins.test/job/demo/12', 'a.bin');
      expect((result as Ok<int?, dynamic>).value, isNull);
    });
  });
}
