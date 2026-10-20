import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/parameter_file.dart';

/// P5-18: verifies `triggerBuild`'s request construction for the
/// parameterized case (endpoint choice, form-encoded body, `?token=`)
/// without submitting it to a real server — some of the parameterized jobs
/// on the available live Jenkins instance have real side effects
/// (deploy/push-image/send-email params), so this is done against a fake
/// adapter instead, per the user's choice for P5-18.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.locationHeader, this.statusCode = 201});

  final String? locationHeader;
  final int statusCode;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '',
      statusCode,
      headers: locationHeader == null
          ? null
          : {
              'location': [locationHeader!],
            },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'no parameters, non-parameterized job -> POST .../build with no body',
    () async {
      final adapter = _RecordingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.triggerBuild(
        'https://jenkins.test/job/demo',
        isParameterized: false,
      );

      expect(result, isA<Ok<String?, dynamic>>());
      expect(adapter.lastRequest?.path, 'https://jenkins.test/job/demo/build');
      expect(adapter.lastRequest?.data, isNull);
    },
  );

  test(
    'returns the rewritten queue-item URL from the Location header (US-PIPE-01)',
    () async {
      final adapter = _RecordingAdapter(
        locationHeader: 'https://internal.jenkins.test/queue/item/42/',
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.triggerBuild(
        'https://jenkins.test/job/demo',
        isParameterized: false,
      );

      // Result has no `==` override (see core/error/result.dart), so
      // pattern-match out the value rather than comparing instances.
      expect(result, isA<Ok<String?, dynamic>>());
      expect(
        (result as Ok<String?, dynamic>).value,
        'https://jenkins.test/queue/item/42/',
      );
    },
  );

  test(
    'returns null when the trigger response has no Location header',
    () async {
      final adapter = _RecordingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.triggerBuild(
        'https://jenkins.test/job/demo',
        isParameterized: false,
      );

      expect(result, isA<Ok<String?, dynamic>>());
      expect((result as Ok<String?, dynamic>).value, isNull);
    },
  );

  test(
    'with parameters -> POST .../buildWithParameters, form-urlencoded body',
    () async {
      final adapter = _RecordingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      await repo.triggerBuild(
        'https://jenkins.test/job/demo',
        isParameterized: true,
        parameters: {'BRANCH': 'main', 'DEPLOY': 'false'},
      );

      expect(
        adapter.lastRequest?.path,
        'https://jenkins.test/job/demo/buildWithParameters',
      );
      expect(adapter.lastRequest?.data, {'BRANCH': 'main', 'DEPLOY': 'false'});
      expect(
        adapter.lastRequest?.contentType,
        startsWith('application/x-www-form-urlencoded'),
      );
    },
  );

  test(
    'isParameterized true with no explicit parameters still uses buildWithParameters',
    () async {
      final adapter = _RecordingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      await repo.triggerBuild(
        'https://jenkins.test/job/demo',
        isParameterized: true,
      );

      expect(
        adapter.lastRequest?.path,
        'https://jenkins.test/job/demo/buildWithParameters',
      );
    },
  );

  test(
    'paramToken is appended as a ?token= query parameter when present',
    () async {
      final adapter = _RecordingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      await repo.triggerBuild(
        'https://jenkins.test/job/demo',
        isParameterized: false,
        paramToken: 'secret-token',
      );

      expect(adapter.lastRequest?.queryParameters['token'], 'secret-token');
    },
  );

  test('an empty paramToken is not sent as a query parameter', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
      ..httpClientAdapter = adapter;
    final repo = JenkinsRepositoryImpl(dio);

    await repo.triggerBuild(
      'https://jenkins.test/job/demo',
      isParameterized: false,
      paramToken: '',
    );

    expect(adapter.lastRequest?.queryParameters.containsKey('token'), isFalse);
  });

  test('cancelBuild POSTs {buildUrl}stop', () async {
    final adapter = _RecordingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
      ..httpClientAdapter = adapter;
    final repo = JenkinsRepositoryImpl(dio);

    await repo.cancelBuild('https://jenkins.test/job/demo/42/');

    expect(adapter.lastRequest?.path, 'https://jenkins.test/job/demo/42/stop');
  });

  test(
    '303 for a duplicate of an already-queued build is a success (AUD-37)',
    () async {
      final adapter = _RecordingAdapter(
        statusCode: 303,
        locationHeader: 'http://jenkins.internal:8080/queue/item/75/',
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.triggerBuild(
        'https://jenkins.test/job/demo',
        isParameterized: true,
        parameters: {'BRANCH': 'main'},
      );

      expect(result, isA<Ok<String?, AppFailure>>());
      // The existing queue item, rewritten to the active server.
      expect(
        (result as Ok<String?, AppFailure>).value,
        'https://jenkins.test/queue/item/75/',
      );
    },
  );

  test('a 4xx trigger response is still a failure', () async {
    final adapter = _RecordingAdapter(statusCode: 403);
    final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
      ..httpClientAdapter = adapter;
    final repo = JenkinsRepositoryImpl(dio);

    final result = await repo.triggerBuild(
      'https://jenkins.test/job/demo',
      isParameterized: false,
    );

    expect(
      (result as Err<String?, AppFailure>).error,
      isA<PermissionFailure>(),
    );
  });

  test(
    'file parameters go as a multipart part named after the parameter',
    () async {
      final directory = Directory.systemTemp.createTempSync('jt-upload');
      addTearDown(() => directory.deleteSync(recursive: true));
      final local = File('${directory.path}/cfg.json')..writeAsStringSync('{}');
      final adapter = _RecordingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;

      await JenkinsRepositoryImpl(dio).triggerBuild(
        'https://jenkins.test/job/demo',
        isParameterized: true,
        parameters: {'BRANCH': 'main'},
        files: {
          'config.json': ParameterFile(
            fileName: 'cfg.json',
            path: local.path,
            sizeBytes: 2,
          ),
        },
      );

      expect(
        adapter.lastRequest?.path,
        'https://jenkins.test/job/demo/buildWithParameters',
      );
      final form = adapter.lastRequest?.data as FormData;
      expect(Map.fromEntries(form.fields), {'BRANCH': 'main'});
      expect(form.files.single.key, 'config.json');
      expect(form.files.single.value.filename, 'cfg.json');
      expect(
        adapter.lastRequest?.contentType,
        startsWith('multipart/form-data'),
      );
    },
  );
}
