import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';

/// Same shape as `jenkins_repository_impl_test_report_test.dart`'s
/// `_FixedResponseAdapter`.
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
  group('JenkinsRepositoryImpl.fetchPipelineStages (US-PIPE-04)', () {
    test('GETs {buildUrl}wfapi/describe and parses stages', () async {
      final adapter = _FixedResponseAdapter(200, {
        'stages': [
          {'id': '6', 'name': 'Build', 'status': 'SUCCESS'},
        ],
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchPipelineStages(
        'https://jenkins.test/job/demo/12',
      );

      expect(
        adapter.lastRequest?.path,
        'https://jenkins.test/job/demo/12/wfapi/describe',
      );
      expect(result, isA<Ok<List<PipelineStage>?, dynamic>>());
      final stages = (result as Ok<List<PipelineStage>?, dynamic>).value;
      expect(stages, hasLength(1));
      expect(stages!.single.name, 'Build');
    });

    test('returns Ok(null) — not an Err — when Jenkins 404s (not a pipeline job)', () async {
      final adapter = _FixedResponseAdapter(404);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchPipelineStages(
        'https://jenkins.test/job/demo/12',
      );

      expect(result, isA<Ok<List<PipelineStage>?, dynamic>>());
      expect((result as Ok<List<PipelineStage>?, dynamic>).value, isNull);
    });

    test('a non-404 failure still maps to Err', () async {
      final adapter = _FixedResponseAdapter(500);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchPipelineStages(
        'https://jenkins.test/job/demo/12',
      );

      expect(result, isA<Err<List<PipelineStage>?, dynamic>>());
    });
  });
}
