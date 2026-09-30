import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/pending_input.dart';

/// Same shape as `jenkins_repository_impl_test_report_test.dart`'s
/// `_FixedResponseAdapter`, but the body is a JSON array (or the request
/// path is echoed as a plain-text response) so both `fetchPendingInput`
/// and `submitInput` can be exercised with one adapter.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter({this.statusCode = 200, this.body});

  final int statusCode;
  final dynamic body;

  /// A raw (non-JSON) response body, e.g. a Jenkins HTML error page.
  String? bodyOverride;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    // Only claim a JSON content-type when actually returning JSON --
    // the submit/abort endpoints in these tests echo back the plain
    // request path, and Dio's default json ResponseType would otherwise
    // try (and fail) to decode that as JSON purely because the header
    // said so.
    return ResponseBody.fromString(
      bodyOverride ?? (body == null ? options.path : jsonEncode(body)),
      statusCode,
      headers: body == null
          ? {}
          : {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('JenkinsRepositoryImpl.fetchPendingInput (US-PIPE-05)', () {
    test(
      'GETs {buildUrl}wfapi/pendingInputActions and parses the first entry',
      () async {
        final adapter = _ScriptedAdapter(
          body: [
            {'id': 'Deploy to prod', 'message': 'Approve?'},
          ],
        );
        final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
          ..httpClientAdapter = adapter;
        final repo = JenkinsRepositoryImpl(dio);

        final result = await repo.fetchPendingInput(
          'https://jenkins.test/job/demo/12',
        );

        expect(
          adapter.lastRequest?.path,
          'https://jenkins.test/job/demo/12/wfapi/pendingInputActions',
        );
        expect(result, isA<Ok<PendingInput?, dynamic>>());
        expect(
          (result as Ok<PendingInput?, dynamic>).value?.id,
          'Deploy to prod',
        );
      },
    );

    test('returns Ok(null) when the array is empty', () async {
      final adapter = _ScriptedAdapter(body: <dynamic>[]);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchPendingInput(
        'https://jenkins.test/job/demo/12',
      );

      expect(result, isA<Ok<PendingInput?, dynamic>>());
      expect((result as Ok<PendingInput?, dynamic>).value, isNull);
    });

    test('returns Ok(null) — not an Err — when Jenkins 404s', () async {
      final adapter = _ScriptedAdapter(statusCode: 404, body: <dynamic>[]);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchPendingInput(
        'https://jenkins.test/job/demo/12',
      );

      expect(result, isA<Ok<PendingInput?, dynamic>>());
      expect((result as Ok<PendingInput?, dynamic>).value, isNull);
    });
  });

  group('JenkinsRepositoryImpl.submitInput (US-PIPE-05)', () {
    test(
      'proceed with no parameters POSTs {buildUrl}input/{id}/proceedEmpty',
      () async {
        final adapter = _ScriptedAdapter(statusCode: 200);
        final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
          ..httpClientAdapter = adapter;
        final repo = JenkinsRepositoryImpl(dio);

        final result = await repo.submitInput(
          buildUrl: 'https://jenkins.test/job/demo/12',
          inputId: 'Deploy to prod',
          proceed: true,
        );

        expect(result, isA<Ok<void, dynamic>>());
        expect(
          adapter.lastRequest?.path,
          'https://jenkins.test/job/demo/12/input/Deploy%20to%20prod/proceedEmpty',
        );
      },
    );

    test(
      'proceed with parameters POSTs .../proceed with a Stapler json field',
      () async {
        final adapter = _ScriptedAdapter(statusCode: 200);
        final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
          ..httpClientAdapter = adapter;
        final repo = JenkinsRepositoryImpl(dio);

        final result = await repo.submitInput(
          buildUrl: 'https://jenkins.test/job/demo/12',
          inputId: 'x',
          proceed: true,
          parameters: {'VERSION': '9.9.9', 'REGION': 'us-east-1'},
        );

        expect(result, isA<Ok<void, dynamic>>());
        expect(
          adapter.lastRequest?.path,
          'https://jenkins.test/job/demo/12/input/x/proceed',
        );
        expect(
          adapter.lastRequest?.contentType,
          startsWith('application/x-www-form-urlencoded'),
        );
        // The real contract (verified on the fixture Jenkins, P11-02).
        final form = adapter.lastRequest?.data as Map<String, dynamic>;
        expect(jsonDecode(form['json'] as String), {
          'parameter': [
            {'name': 'VERSION', 'value': '9.9.9'},
            {'name': 'REGION', 'value': 'us-east-1'},
          ],
        });
      },
    );

    test(
      'a 400 permission page maps to PermissionFailure, not ServerFailure',
      () async {
        final adapter = _ScriptedAdapter(statusCode: 400, body: null)
          ..bodyOverride =
              '<html><h1>Error</h1><p>You need to have Job/Build permissions '
              'to submit this.</p></html>';
        final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
          ..httpClientAdapter = adapter;
        final repo = JenkinsRepositoryImpl(dio);

        final result = await repo.submitInput(
          buildUrl: 'https://jenkins.test/job/demo/12',
          inputId: 'x',
          proceed: true,
        );

        expect(
          (result as Err<void, AppFailure>).error,
          isA<PermissionFailure>(),
        );
      },
    );

    test('any other 400 stays a ServerFailure', () async {
      final adapter = _ScriptedAdapter(statusCode: 400)
        ..bodyOverride = '<html>Bad request</html>';
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.submitInput(
        buildUrl: 'https://jenkins.test/job/demo/12',
        inputId: 'x',
        proceed: false,
      );

      expect((result as Err<void, AppFailure>).error, isA<ServerFailure>());
    });

    test('reject POSTs {buildUrl}input/{id}/abort', () async {
      final adapter = _ScriptedAdapter(statusCode: 200);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      await repo.submitInput(
        buildUrl: 'https://jenkins.test/job/demo/12',
        inputId: 'x',
        proceed: false,
      );

      expect(
        adapter.lastRequest?.path,
        'https://jenkins.test/job/demo/12/input/x/abort',
      );
    });

    test('a failure maps to Err', () async {
      final adapter = _ScriptedAdapter(statusCode: 500);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.submitInput(
        buildUrl: 'https://jenkins.test/job/demo/12',
        inputId: 'x',
        proceed: true,
      );

      expect(result, isA<Err<void, dynamic>>());
    });
  });
}
