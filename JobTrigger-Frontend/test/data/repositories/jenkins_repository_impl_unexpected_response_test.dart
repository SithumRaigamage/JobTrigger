import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';

/// Returns a fixed raw body with a caller-chosen content type -- what an
/// SSO / reverse proxy in front of Jenkins actually sends back.
class _RawAdapter implements HttpClientAdapter {
  _RawAdapter(this.body, this.contentType);

  final String body;
  final String contentType;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body,
    200,
    headers: {
      Headers.contentTypeHeader: [contentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

JenkinsRepositoryImpl _repo(String body, String contentType) =>
    JenkinsRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = _RawAdapter(body, contentType),
    );

Matcher get _unexpected => isA<Err<Object?, AppFailure>>().having(
  (err) => err.error,
  'error',
  isA<UnexpectedResponseFailure>(),
);

void main() {
  group(
    'JenkinsRepositoryImpl never throws on unexpected responses (AUD-11)',
    () {
      test(
        'an HTML login page returned with 200 is a failure, not a crash',
        () async {
          final repo = _repo('<html><body>Sign in</body></html>', 'text/html');
          expect(await repo.fetchJobTree(), _unexpected);
          expect(
            await repo.fetchJobDetail('https://jenkins.test/job/a/'),
            _unexpected,
          );
          expect(
            await repo.fetchQueueItem('https://jenkins.test/queue/item/1/'),
            _unexpected,
          );
        },
      );

      test('JSON with an unexpected shape is a failure, not a crash', () async {
        final repo = _repo('{"jobs": "not-a-list"}', Headers.jsonContentType);
        expect(await repo.fetchJobTree(), _unexpected);
      });

      test('a body declared as JSON that is not JSON is a failure', () async {
        final repo = _repo('this is not json', Headers.jsonContentType);
        expect(await repo.fetchJobTree(), _unexpected);
      });
    },
  );
}
