import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';

/// P5-18: verifies `triggerBuild`'s request construction for the
/// parameterized case (endpoint choice, form-encoded body, `?token=`)
/// without submitting it to a real server — some of the parameterized jobs
/// on the available live Jenkins instance have real side effects
/// (deploy/push-image/send-email params), so this is done against a fake
/// adapter instead, per the user's choice for P5-18.
class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString('', 201);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('no parameters, non-parameterized job -> POST .../build with no body', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))..httpClientAdapter = adapter;
    final repo = JenkinsRepositoryImpl(dio);

    final result = await repo.triggerBuild('https://jenkins.test/job/demo', isParameterized: false);

    expect(result, isA<Ok<void, dynamic>>());
    expect(adapter.lastRequest?.path, 'https://jenkins.test/job/demo/build');
    expect(adapter.lastRequest?.data, isNull);
  });

  test('with parameters -> POST .../buildWithParameters, form-urlencoded body', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))..httpClientAdapter = adapter;
    final repo = JenkinsRepositoryImpl(dio);

    await repo.triggerBuild(
      'https://jenkins.test/job/demo',
      isParameterized: true,
      parameters: {'BRANCH': 'main', 'DEPLOY': 'false'},
    );

    expect(adapter.lastRequest?.path, 'https://jenkins.test/job/demo/buildWithParameters');
    expect(adapter.lastRequest?.data, {'BRANCH': 'main', 'DEPLOY': 'false'});
    expect(
      adapter.lastRequest?.contentType,
      startsWith('application/x-www-form-urlencoded'),
    );
  });

  test('isParameterized true with no explicit parameters still uses buildWithParameters', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))..httpClientAdapter = adapter;
    final repo = JenkinsRepositoryImpl(dio);

    await repo.triggerBuild('https://jenkins.test/job/demo', isParameterized: true);

    expect(adapter.lastRequest?.path, 'https://jenkins.test/job/demo/buildWithParameters');
  });

  test('paramToken is appended as a ?token= query parameter when present', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))..httpClientAdapter = adapter;
    final repo = JenkinsRepositoryImpl(dio);

    await repo.triggerBuild(
      'https://jenkins.test/job/demo',
      isParameterized: false,
      paramToken: 'secret-token',
    );

    expect(adapter.lastRequest?.queryParameters['token'], 'secret-token');
  });

  test('an empty paramToken is not sent as a query parameter', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))..httpClientAdapter = adapter;
    final repo = JenkinsRepositoryImpl(dio);

    await repo.triggerBuild('https://jenkins.test/job/demo', isParameterized: false, paramToken: '');

    expect(adapter.lastRequest?.queryParameters.containsKey('token'), isFalse);
  });

  test('cancelBuild POSTs {buildUrl}stop', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))..httpClientAdapter = adapter;
    final repo = JenkinsRepositoryImpl(dio);

    await repo.cancelBuild('https://jenkins.test/job/demo/42/');

    expect(adapter.lastRequest?.path, 'https://jenkins.test/job/demo/42/stop');
  });
}
