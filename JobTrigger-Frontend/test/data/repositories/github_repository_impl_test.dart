import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/domain/github/github_job.dart';
import 'package:job_trigger/domain/github/github_workflow.dart';
import 'package:job_trigger/domain/github/github_workflow_run.dart';

class _FixedResponseAdapter implements HttpClientAdapter {
  _FixedResponseAdapter(this.statusCode, this.body);

  final int statusCode;
  final dynamic body;
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

/// Serves a scripted response per host, recording every request, so a
/// redirect from `api.github.com` to a storage host can be followed.
class _HostAdapter implements HttpClientAdapter {
  _HostAdapter(this.responses);

  /// host -> (status, body, headers)
  final Map<String, (int, String, Map<String, List<String>>)> responses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body, headers) = responses[options.uri.host]!;
    return ResponseBody.fromString(body, status, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('GitHubRepositoryImpl.fetchRepos (US-GH-REPO-01)', () {
    test('GETs /user/repos and parses the array', () async {
      final adapter = _FixedResponseAdapter(200, [
        {
          'id': 1,
          'name': 'repo-a',
          'full_name': 'octocat/repo-a',
          'owner': {'login': 'octocat'},
        },
        {
          'id': 2,
          'name': 'repo-b',
          'full_name': 'octocat/repo-b',
          'owner': {'login': 'octocat'},
        },
      ]);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = adapter;
      final repo = GitHubRepositoryImpl(dio);

      final result = await repo.fetchRepos();

      expect(adapter.lastRequest?.path, '/user/repos');
      expect(adapter.lastRequest?.queryParameters['per_page'], 100);
      expect(result, isA<Ok<List<GitHubRepo>, dynamic>>());
      final repos = (result as Ok<List<GitHubRepo>, dynamic>).value;
      expect(repos, hasLength(2));
      expect(repos.first.fullName, 'octocat/repo-a');
    });

    test('a failure maps to Err', () async {
      final adapter = _FixedResponseAdapter(500, {'message': 'boom'});
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = adapter;
      final repo = GitHubRepositoryImpl(dio);

      final result = await repo.fetchRepos();

      expect(result, isA<Err<List<GitHubRepo>, dynamic>>());
    });
  });

  group('GitHubRepositoryImpl.fetchWorkflows (US-GH-REPO-02)', () {
    test(
      'GETs /repos/{owner}/{repo}/actions/workflows and parses workflows[]',
      () async {
        final adapter = _FixedResponseAdapter(200, {
          'total_count': 1,
          'workflows': [
            {
              'id': 42,
              'name': 'CI',
              'path': '.github/workflows/ci.yml',
              'state': 'active',
            },
          ],
        });
        final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
          ..httpClientAdapter = adapter;
        final repo = GitHubRepositoryImpl(dio);

        final result = await repo.fetchWorkflows('octocat', 'my-repo');

        expect(
          adapter.lastRequest?.path,
          '/repos/octocat/my-repo/actions/workflows',
        );
        expect(result, isA<Ok<List<GitHubWorkflow>, dynamic>>());
        final workflows = (result as Ok<List<GitHubWorkflow>, dynamic>).value;
        expect(workflows, hasLength(1));
        expect(workflows.single.name, 'CI');
      },
    );

    test('a failure maps to Err', () async {
      final adapter = _FixedResponseAdapter(404, {'message': 'Not Found'});
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = adapter;
      final repo = GitHubRepositoryImpl(dio);

      final result = await repo.fetchWorkflows('octocat', 'missing');

      expect(result, isA<Err<List<GitHubWorkflow>, dynamic>>());
    });
  });

  group('GitHubRepositoryImpl.fetchRuns (US-GH-RUN-01)', () {
    Map<String, dynamic> run(
      int id, {
      String status = 'completed',
      String? conclusion = 'success',
    }) => {
      'id': id,
      'run_number': id,
      'display_title': 'Commit $id',
      'event': 'push',
      'status': status,
      'conclusion': conclusion,
      'head_branch': 'main',
      'created_at': '2026-11-08T10:00:00Z',
      'html_url': 'https://github.com/octocat/hello/actions/runs/$id',
    };

    test(
      'GETs the workflow runs and keeps status and conclusion apart',
      () async {
        final adapter = _FixedResponseAdapter(200, {
          'total_count': 2,
          'workflow_runs': [
            run(2, status: 'in_progress', conclusion: null),
            run(1),
          ],
        });
        final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
          ..httpClientAdapter = adapter;

        final result = await GitHubRepositoryImpl(
          dio,
        ).fetchRuns('octocat', 'hello', 42);

        expect(
          adapter.lastRequest?.path,
          '/repos/octocat/hello/actions/workflows/42/runs',
        );
        expect(adapter.lastRequest?.queryParameters['per_page'], 30);
        final runs = (result as Ok<List<GitHubWorkflowRun>, dynamic>).value;
        expect(runs, hasLength(2));
        expect(runs[0].status, 'in_progress');
        expect(runs[0].conclusion, isNull);
        expect(runs[1].status, 'completed');
        expect(runs[1].conclusion, 'success');
        expect(runs[1].title, 'Commit 1');
        expect(runs[1].branch, 'main');
        expect(runs[1].createdAt, DateTime.utc(2026, 11, 8, 10));
      },
    );

    test('asks for the requested page', () async {
      final adapter = _FixedResponseAdapter(200, {
        'workflow_runs': <dynamic>[],
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = adapter;

      await GitHubRepositoryImpl(dio).fetchRuns('o', 'r', 1, page: 3);

      expect(adapter.lastRequest?.queryParameters['page'], 3);
      expect(adapter.lastRequest?.queryParameters['per_page'], 30);
    });

    test('falls back to the workflow name, then a numbered title', () async {
      final adapter = _FixedResponseAdapter(200, {
        'workflow_runs': [
          {'id': 1, 'run_number': 7, 'name': 'CI', 'status': 'queued'},
          {'id': 2, 'run_number': 8, 'status': 'queued'},
        ],
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = adapter;

      final result = await GitHubRepositoryImpl(dio).fetchRuns('o', 'r', 1);

      final runs = (result as Ok<List<GitHubWorkflowRun>, dynamic>).value;
      expect(runs[0].title, 'CI');
      expect(runs[1].title, 'Run #8');
      expect(runs[1].createdAt, isNull);
    });

    test('a workflow that never ran is an empty list, not an error', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = _FixedResponseAdapter(200, {
          'total_count': 0,
          'workflow_runs': <dynamic>[],
        });

      final result = await GitHubRepositoryImpl(dio).fetchRuns('o', 'r', 1);

      expect((result as Ok<List<GitHubWorkflowRun>, dynamic>).value, isEmpty);
    });

    test('404 maps to NotFoundFailure', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = _FixedResponseAdapter(404, {
          'message': 'Not Found',
        });

      final result = await GitHubRepositoryImpl(dio).fetchRuns('o', 'r', 1);

      expect(result, isA<Err<List<GitHubWorkflowRun>, AppFailure>>());
      expect(
        (result as Err<List<GitHubWorkflowRun>, AppFailure>).error,
        isA<NotFoundFailure>(),
      );
    });
  });

  group(
    'GitHubRepositoryImpl trigger / fetchRun / cancel (US-GH-RUN-02..04)',
    () {
      Dio dioWith(_FixedResponseAdapter a) =>
          Dio(BaseOptions(baseUrl: 'https://api.github.com'))
            ..httpClientAdapter = a;

      test('triggerRun POSTs ref and inputs as a JSON object', () async {
        final adapter = _FixedResponseAdapter(204, null);

        final result = await GitHubRepositoryImpl(
          dioWith(adapter),
        ).triggerRun('o', 'r', 42, ref: 'main', inputs: {'env': 'a"b'});

        expect(result, isA<Ok<void, AppFailure>>());
        expect(adapter.lastRequest?.method, 'POST');
        expect(
          adapter.lastRequest?.path,
          '/repos/o/r/actions/workflows/42/dispatches',
        );
        expect(adapter.lastRequest?.data, {
          'ref': 'main',
          'inputs': {'env': 'a"b'},
        });
      });

      test('triggerRun omits inputs when there are none', () async {
        final adapter = _FixedResponseAdapter(204, null);

        await GitHubRepositoryImpl(
          dioWith(adapter),
        ).triggerRun('o', 'r', 1, ref: 'main');

        expect(adapter.lastRequest?.data, {'ref': 'main'});
      });

      test(
        'a 422 becomes DispatchRejectedFailure with GitHub detail',
        () async {
          final adapter = _FixedResponseAdapter(422, {
            'message': "Workflow does not have 'workflow_dispatch' trigger",
          });

          final result = await GitHubRepositoryImpl(
            dioWith(adapter),
          ).triggerRun('o', 'r', 1, ref: 'main');

          final failure = (result as Err<void, AppFailure>).error;
          expect(failure, isA<DispatchRejectedFailure>());
          expect(failure.message, contains('workflow_dispatch'));
          expect(failure.message, contains('GitHub said'));
        },
      );

      test('fetchRun GETs one run', () async {
        final adapter = _FixedResponseAdapter(200, {
          'id': 5,
          'run_number': 5,
          'display_title': 'Go',
          'status': 'in_progress',
          'conclusion': null,
        });

        final result = await GitHubRepositoryImpl(
          dioWith(adapter),
        ).fetchRun('o', 'r', 5);

        expect(adapter.lastRequest?.path, '/repos/o/r/actions/runs/5');
        final run = (result as Ok<GitHubWorkflowRun, AppFailure>).value;
        expect(run.status, 'in_progress');
        expect(run.isActive, isTrue);
      });

      test('cancelRun POSTs to .../cancel and accepts 202', () async {
        final adapter = _FixedResponseAdapter(202, null);

        final result = await GitHubRepositoryImpl(
          dioWith(adapter),
        ).cancelRun('o', 'r', 5);

        expect(result, isA<Ok<void, AppFailure>>());
        expect(adapter.lastRequest?.method, 'POST');
        expect(adapter.lastRequest?.path, '/repos/o/r/actions/runs/5/cancel');
      });
    },
  );

  group('GitHubRepositoryImpl.fetchJobs (US-GH-RUN-05)', () {
    test(
      'parses jobs with their steps, keeping status and conclusion',
      () async {
        final adapter = _FixedResponseAdapter(200, {
          'total_count': 2,
          'jobs': [
            {
              'id': 11,
              'name': 'build (ubuntu)',
              'status': 'completed',
              'conclusion': 'failure',
              'steps': [
                {
                  'number': 1,
                  'name': 'Checkout',
                  'status': 'completed',
                  'conclusion': 'success',
                },
                {
                  'number': 2,
                  'name': 'Test',
                  'status': 'completed',
                  'conclusion': 'failure',
                },
                {
                  'number': 3,
                  'name': 'Upload',
                  'status': 'completed',
                  'conclusion': 'skipped',
                },
              ],
            },
            {'id': 12, 'name': 'lint', 'status': 'queued'},
          ],
        });
        final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
          ..httpClientAdapter = adapter;

        final result = await GitHubRepositoryImpl(dio).fetchJobs('o', 'r', 5);

        expect(adapter.lastRequest?.path, '/repos/o/r/actions/runs/5/jobs');
        final jobs = (result as Ok<List<GitHubJob>, AppFailure>).value;
        expect(jobs.map((j) => j.name), ['build (ubuntu)', 'lint']);
        expect(jobs[0].steps.map((s) => s.name), [
          'Checkout',
          'Test',
          'Upload',
        ]);
        expect(jobs[0].steps[1].conclusion, 'failure');
        expect(jobs[0].steps[2].label, 'Skipped');
        // A job GitHub hasn't started has no steps yet.
        expect(jobs[1].steps, isEmpty);
        expect(jobs[1].conclusion, isNull);
      },
    );

    test('a 403 with no rate-limit header is a permission failure', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = _FixedResponseAdapter(403, {'message': 'x'});

      final result = await GitHubRepositoryImpl(dio).fetchJobs('o', 'r', 5);

      expect(
        (result as Err<List<GitHubJob>, AppFailure>).error,
        isA<PermissionFailure>(),
      );
    });
  });

  group('GitHubRepositoryImpl.fetchJobLog (US-GH-LOG-01)', () {
    const signed = 'https://logs.example-storage.test/blob/1?sig=SECRET';

    test('follows the 302 by hand and never sends the token to the storage '
        'host', () async {
      final apiAdapter = _HostAdapter({
        'api.github.com': (
          302,
          '',
          {
            'location': [signed],
          },
        ),
      });
      final api = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..options.headers['Authorization'] = 'Bearer ghp_TOKEN'
        ..httpClientAdapter = apiAdapter;
      final storageAdapter = _HostAdapter({
        'logs.example-storage.test': (200, 'line one\nline two\n', {}),
      });
      final storage = Dio()..httpClientAdapter = storageAdapter;

      final result = await GitHubRepositoryImpl(
        api,
        downloadDio: storage,
      ).fetchJobLog('o', 'r', 9);

      expect((result as Ok<String, AppFailure>).value, 'line one\nline two\n');
      expect(apiAdapter.requests, hasLength(1));
      expect(apiAdapter.requests.single.path, '/repos/o/r/actions/jobs/9/logs');
      expect(apiAdapter.requests.single.followRedirects, isFalse);
      expect(storageAdapter.requests, hasLength(1));
      expect(storageAdapter.requests.single.uri.toString(), signed);
      expect(
        storageAdapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('a log returned directly (no redirect) is used as is', () async {
      final api = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = _HostAdapter({
          'api.github.com': (200, 'inline log', {}),
        });

      final result = await GitHubRepositoryImpl(api).fetchJobLog('o', 'r', 9);

      expect((result as Ok<String, AppFailure>).value, 'inline log');
    });

    test('a redirect with no Location is an unexpected response', () async {
      final api = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = _HostAdapter({'api.github.com': (302, '', {})});

      final result = await GitHubRepositoryImpl(api).fetchJobLog('o', 'r', 9);

      expect(
        (result as Err<String, AppFailure>).error,
        isA<UnexpectedResponseFailure>(),
      );
    });

    test('logs that are gone or expired map to NotFoundFailure', () async {
      final api = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = _HostAdapter({
          'api.github.com': (404, '{"message":"Not Found"}', {}),
        });

      final result = await GitHubRepositoryImpl(api).fetchJobLog('o', 'r', 9);

      expect((result as Err<String, AppFailure>).error, isA<NotFoundFailure>());
    });

    test(
      'an expired signed URL (storage 403/404) is a failure, not text',
      () async {
        final api = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
          ..httpClientAdapter = _HostAdapter({
            'api.github.com': (
              302,
              '',
              {
                'location': [signed],
              },
            ),
          });
        final storage = Dio()
          ..httpClientAdapter = _HostAdapter({
            'logs.example-storage.test': (404, 'expired', {}),
          });

        final result = await GitHubRepositoryImpl(
          api,
          downloadDio: storage,
        ).fetchJobLog('o', 'r', 9);

        expect(result, isA<Err<String, AppFailure>>());
      },
    );
  });
}
