import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/domain/github/github_workflow.dart';

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
    test('GETs /repos/{owner}/{repo}/actions/workflows and parses workflows[]', () async {
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
    });

    test('a failure maps to Err', () async {
      final adapter = _FixedResponseAdapter(404, {'message': 'Not Found'});
      final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
        ..httpClientAdapter = adapter;
      final repo = GitHubRepositoryImpl(dio);

      final result = await repo.fetchWorkflows('octocat', 'missing');

      expect(result, isA<Err<List<GitHubWorkflow>, dynamic>>());
    });
  });
}
