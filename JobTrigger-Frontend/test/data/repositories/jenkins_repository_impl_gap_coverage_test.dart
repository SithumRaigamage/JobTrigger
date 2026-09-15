import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/domain/jenkins/queue_item.dart';

/// Fills the isolated-repository-test gap for `fetchJobTree`,
/// `fetchJobDetail`, `streamBuildLog`, `fetchJobHistory` and
/// `fetchQueueItem` — previously only exercised indirectly through
/// notifier tests. Mirrors the adapter styles already used by
/// `jenkins_repository_impl_trigger_test.dart` (`_RecordingAdapter`) and
/// `jenkins_repository_impl_pipeline_stages_test.dart`
/// (`_FixedResponseAdapter`).

/// Returns a fixed (status, JSON body) response and records the last
/// request, same shape as `jenkins_repository_impl_pipeline_stages_test.dart`'s
/// `_FixedResponseAdapter`.
class _JsonResponseAdapter implements HttpClientAdapter {
  _JsonResponseAdapter(this.statusCode, [this.body = const {}]);

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

/// Returns a fixed (status, plain-text body, extra headers) response for
/// `streamBuildLog`, which requests `ResponseType.plain` and reads
/// `X-Text-Size`/`X-More-Data` off the response headers rather than a JSON
/// body.
class _PlainTextResponseAdapter implements HttpClientAdapter {
  _PlainTextResponseAdapter(
    this.statusCode, {
    this.text = '',
    this.extraHeaders = const {},
  });

  final int statusCode;
  final String text;
  final Map<String, String> extraHeaders;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      text,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.textPlainContentType],
        for (final entry in extraHeaders.entries) entry.key: [entry.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('JenkinsRepositoryImpl.fetchJobTree', () {
    test(
      'GETs /api/json with the recursive tree query and rewrites job URLs to the active server',
      () async {
        final adapter = _JsonResponseAdapter(200, {
          'jobs': [
            {
              'name': 'demo',
              'url': 'http://internal-jenkins/job/demo/',
              'color': 'blue',
              'lastBuild': {
                'number': 5,
                'url': 'http://internal-jenkins/job/demo/5/',
                'timestamp': 1000,
              },
            },
          ],
        });
        final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
          ..httpClientAdapter = adapter;
        final repo = JenkinsRepositoryImpl(dio);

        final result = await repo.fetchJobTree();

        // fetchJobTree requests a relative path ('/api/json'), so Dio
        // doesn't merge it with baseUrl into RequestOptions.path -- same
        // as `jenkins_client_factory_test.dart`'s relative-path assertions.
        expect(adapter.lastRequest?.path, '/api/json');
        expect(
          adapter.lastRequest?.queryParameters['tree'],
          buildJobTreeQuery(),
        );
        expect(result, isA<Ok<List<JenkinsJob>, dynamic>>());
        final jobs = (result as Ok<List<JenkinsJob>, dynamic>).value;
        expect(jobs, hasLength(1));
        expect(jobs.single.name, 'demo');
        // Host/scheme rewritten to the active server's baseUrl; path kept.
        expect(jobs.single.url, 'https://jenkins.test/job/demo/');
        expect(jobs.single.lastBuild?.url, 'https://jenkins.test/job/demo/5/');
      },
    );

    test('a non-2xx response maps to Err', () async {
      final adapter = _JsonResponseAdapter(500);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchJobTree();

      expect(result, isA<Err<List<JenkinsJob>, dynamic>>());
    });
  });

  group('JenkinsRepositoryImpl.fetchJobDetail', () {
    test(
      'GETs {jobUrl}api/json with the details tree and rewrites the job URL',
      () async {
        final adapter = _JsonResponseAdapter(200, {
          'name': 'demo',
          'url': 'http://internal-jenkins/job/demo/',
          'color': 'blue',
          'healthReport': [
            {'description': 'Build stability', 'score': 80},
          ],
        });
        final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
          ..httpClientAdapter = adapter;
        final repo = JenkinsRepositoryImpl(dio);

        final result = await repo.fetchJobDetail(
          'https://jenkins.test/job/demo',
        );

        expect(
          adapter.lastRequest?.path,
          'https://jenkins.test/job/demo/api/json',
        );
        expect(
          adapter.lastRequest?.queryParameters['tree'],
          'name,url,color,description,'
              'lastBuild[number,url,result,timestamp,duration,building,estimatedDuration,'
              'actions[causes[shortDescription,upstreamProject,upstreamUrl]],'
              'changeSet[items[msg,author[fullName]]],'
              'artifacts[fileName,relativePath]],'
              'healthReport[description,iconClassName,score],'
              'property[parameterDefinitions[name,type,description,defaultParameterValue[value],choices]],'
              'downstreamProjects[name,url]',
        );
        expect(result, isA<Ok<JenkinsJob, dynamic>>());
        final job = (result as Ok<JenkinsJob, dynamic>).value;
        expect(job.name, 'demo');
        // Rewritten to the active server's baseUrl, same as fetchJobTree.
        expect(job.url, 'https://jenkins.test/job/demo/');
        expect(job.healthReport.single.score, 80);
      },
    );

    test('a trailing slash on jobUrl is not doubled', () async {
      final adapter = _JsonResponseAdapter(200, {
        'name': 'demo',
        'url': 'https://jenkins.test/job/demo/',
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      await repo.fetchJobDetail('https://jenkins.test/job/demo/');

      expect(
        adapter.lastRequest?.path,
        'https://jenkins.test/job/demo/api/json',
      );
    });

    test('a non-2xx response maps to Err', () async {
      final adapter = _JsonResponseAdapter(404);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchJobDetail(
        'https://jenkins.test/job/missing',
      );

      expect(result, isA<Err<JenkinsJob, dynamic>>());
    });
  });

  group('JenkinsRepositoryImpl.streamBuildLog', () {
    test(
      'GETs {buildUrl}logText/progressiveText with ?start= and maps the response headers',
      () async {
        final adapter = _PlainTextResponseAdapter(
          200,
          text: 'line one\nline two\n',
          extraHeaders: {'X-Text-Size': '19', 'X-More-Data': 'true'},
        );
        final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
          ..httpClientAdapter = adapter;
        final repo = JenkinsRepositoryImpl(dio);

        final result = await repo.streamBuildLog(
          'https://jenkins.test/job/demo/12',
          start: 0,
        );

        expect(
          adapter.lastRequest?.path,
          'https://jenkins.test/job/demo/12/logText/progressiveText',
        );
        expect(adapter.lastRequest?.queryParameters['start'], 0);
        expect(result, isA<Ok<LogChunk, dynamic>>());
        final chunk = (result as Ok<LogChunk, dynamic>).value;
        expect(chunk.text, 'line one\nline two\n');
        expect(chunk.nextOffset, 19);
        expect(chunk.hasMoreData, isTrue);
      },
    );

    test(
      'falls back to start + text.length and hasMoreData=false when the headers are absent',
      () async {
        final adapter = _PlainTextResponseAdapter(200, text: 'abcde');
        final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
          ..httpClientAdapter = adapter;
        final repo = JenkinsRepositoryImpl(dio);

        final result = await repo.streamBuildLog(
          'https://jenkins.test/job/demo/12/',
          start: 10,
        );

        expect(result, isA<Ok<LogChunk, dynamic>>());
        final chunk = (result as Ok<LogChunk, dynamic>).value;
        expect(chunk.nextOffset, 15); // start (10) + text.length (5)
        expect(chunk.hasMoreData, isFalse);
      },
    );

    test('start defaults to 0 when not passed', () async {
      final adapter = _PlainTextResponseAdapter(200, text: '');
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      await repo.streamBuildLog('https://jenkins.test/job/demo/12');

      expect(adapter.lastRequest?.queryParameters['start'], 0);
    });

    test('a non-2xx response maps to Err', () async {
      final adapter = _PlainTextResponseAdapter(500);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.streamBuildLog(
        'https://jenkins.test/job/demo/12',
      );

      expect(result, isA<Err<LogChunk, dynamic>>());
    });
  });

  group('JenkinsRepositoryImpl.fetchJobHistory', () {
    test(
      'GETs {jobUrl}api/json with the history tree and rewrites build URLs',
      () async {
        final adapter = _JsonResponseAdapter(200, {
          'builds': [
            {
              'number': 13,
              'url': 'http://internal-jenkins/job/demo/13/',
              'result': 'SUCCESS',
              'timestamp': 2000,
              'building': false,
            },
          ],
        });
        final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
          ..httpClientAdapter = adapter;
        final repo = JenkinsRepositoryImpl(dio);

        final result = await repo.fetchJobHistory(
          'https://jenkins.test/job/demo',
        );

        expect(
          adapter.lastRequest?.path,
          'https://jenkins.test/job/demo/api/json',
        );
        expect(
          adapter.lastRequest?.queryParameters['tree'],
          'builds[number,url,result,timestamp,duration,displayName,building,'
              'estimatedDuration,actions[parameters[name,value]]]{0,20}',
        );
        expect(result, isA<Ok<List<JenkinsBuild>, dynamic>>());
        final builds = (result as Ok<List<JenkinsBuild>, dynamic>).value;
        expect(builds, hasLength(1));
        expect(builds.single.number, 13);
        expect(builds.single.result, 'SUCCESS');
        // Rewritten to the active server's baseUrl.
        expect(builds.single.url, 'https://jenkins.test/job/demo/13/');
      },
    );

    test('returns an empty list when the response has no builds key', () async {
      final adapter = _JsonResponseAdapter(200, const {});
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchJobHistory(
        'https://jenkins.test/job/demo',
      );

      expect(result, isA<Ok<List<JenkinsBuild>, dynamic>>());
      expect((result as Ok<List<JenkinsBuild>, dynamic>).value, isEmpty);
    });

    test('a non-2xx response maps to Err', () async {
      final adapter = _JsonResponseAdapter(503);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchJobHistory(
        'https://jenkins.test/job/demo',
      );

      expect(result, isA<Err<List<JenkinsBuild>, dynamic>>());
    });
  });

  group('JenkinsRepositoryImpl.fetchQueueItem', () {
    test('GETs {queueItemUrl}api/json and maps the queue item', () async {
      final adapter = _JsonResponseAdapter(200, {
        'why': 'Waiting for next available executor',
        'cancelled': false,
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchQueueItem(
        'https://jenkins.test/queue/item/42',
      );

      expect(
        adapter.lastRequest?.path,
        'https://jenkins.test/queue/item/42/api/json',
      );
      expect(result, isA<Ok<QueueItem, dynamic>>());
      final item = (result as Ok<QueueItem, dynamic>).value;
      expect(item.why, 'Waiting for next available executor');
      expect(item.cancelled, isFalse);
      expect(item.executable, isNull);
      expect(item.isResolved, isFalse);
    });

    test(
      'a trailing slash on queueItemUrl is not doubled, and executable is parsed once assigned',
      () async {
        final adapter = _JsonResponseAdapter(200, {
          'cancelled': false,
          'executable': {
            'number': 7,
            'url': 'https://jenkins.test/job/demo/7/',
          },
        });
        final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
          ..httpClientAdapter = adapter;
        final repo = JenkinsRepositoryImpl(dio);

        final result = await repo.fetchQueueItem(
          'https://jenkins.test/queue/item/42/',
        );

        expect(
          adapter.lastRequest?.path,
          'https://jenkins.test/queue/item/42/api/json',
        );
        expect(result, isA<Ok<QueueItem, dynamic>>());
        final item = (result as Ok<QueueItem, dynamic>).value;
        expect(item.executable?.number, 7);
        expect(item.executable?.url, 'https://jenkins.test/job/demo/7/');
        expect(item.isResolved, isTrue);
      },
    );

    test(
      'rewrites executable.url to the active server, like every other job/build URL',
      () async {
        // Regression test: fetchQueueItem previously returned
        // executable.url unrewritten, unlike fetchJobTree/fetchJobDetail/
        // fetchJobHistory/triggerBuild's Location header, all of which go
        // through jenkins_url_rewriter.
        final adapter = _JsonResponseAdapter(200, {
          'cancelled': false,
          'executable': {
            'number': 7,
            'url': 'https://internal.jenkins.test/job/demo/7/',
          },
        });
        final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
          ..httpClientAdapter = adapter;
        final repo = JenkinsRepositoryImpl(dio);

        final result = await repo.fetchQueueItem(
          'https://jenkins.test/queue/item/42/',
        );

        final item = (result as Ok<QueueItem, dynamic>).value;
        expect(item.executable?.url, 'https://jenkins.test/job/demo/7/');
      },
    );

    test('a non-2xx response maps to Err', () async {
      final adapter = _JsonResponseAdapter(404);
      final dio = Dio(BaseOptions(baseUrl: 'https://jenkins.test'))
        ..httpClientAdapter = adapter;
      final repo = JenkinsRepositoryImpl(dio);

      final result = await repo.fetchQueueItem(
        'https://jenkins.test/queue/item/999',
      );

      expect(result, isA<Err<QueueItem, dynamic>>());
    });
  });
}
