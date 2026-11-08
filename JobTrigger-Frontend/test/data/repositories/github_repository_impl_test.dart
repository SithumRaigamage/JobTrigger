import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
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
}
