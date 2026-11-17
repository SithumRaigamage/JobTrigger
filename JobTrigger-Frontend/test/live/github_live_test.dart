@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/datasources/github_client_factory.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';

/// P8-26 / P8-27: the app's own GitHub client and repository against a real
/// repository that has three workflows named "With inputs" (a
/// `workflow_dispatch` with inputs), "No inputs" (a bare `workflow_dispatch`)
/// and "Disabled one" (disabled). Skipped unless `GITHUB_LIVE_TOKEN` and
/// `GITHUB_LIVE_REPO` (`owner/name`) are set:
///
///   GITHUB_LIVE_TOKEN=YOUR_TOKEN GITHUB_LIVE_REPO=owner/name \
///   flutter test test/live/github_live_test.dart
///
/// It dispatches real runs on that repository: use a throwaway one.
void main() {
  final env = Platform.environment;
  final token = env['GITHUB_LIVE_TOKEN'];
  final full = env['GITHUB_LIVE_REPO'];
  final skip = (token == null || full == null)
      ? 'set GITHUB_LIVE_TOKEN and GITHUB_LIVE_REPO to run'
      : false;

  T ok<T>(Result<T, AppFailure> result) {
    expect(result, isA<Ok<T, AppFailure>>(), reason: '$result');
    return (result as Ok<T, AppFailure>).value;
  }

  late GitHubRepositoryImpl repo;
  late String owner;
  late String name;
  setUp(() {
    if (skip != false) return;
    repo = GitHubRepositoryImpl(buildGitHubDio(token: token));
    owner = full!.split('/').first;
    name = full.split('/').last;
  });

  test('the repository is listed, and its three workflows are read with their '
      'state', () async {
    expect(ok(await repo.fetchRepos()).map((r) => r.fullName), contains(full));
    final workflows = ok(await repo.fetchWorkflows(owner, name));
    final byName = {for (final w in workflows) w.name: w};
    expect(byName['With inputs']!.isActive, isTrue);
    expect(byName['No inputs']!.isActive, isTrue);
    expect(byName['Disabled one']!.isActive, isFalse);
    expect(byName['Disabled one']!.state, 'disabled_manually');
  }, skip: skip);

  test(
    'dispatch with inputs, then watch the run, its jobs and a log',
    () async {
      final workflows = ok(await repo.fetchWorkflows(owner, name));
      final w = workflows.firstWhere((w) => w.name == 'With inputs');
      final before = ok(await repo.fetchRuns(owner, name, w.id)).length;

      ok(
        await repo.triggerRun(
          owner,
          name,
          w.id,
          ref: 'main',
          inputs: {
            'environment': 'staging',
            'verbose': 'false',
            'note': 'live test',
          },
        ),
      );

      // GitHub queues the run a moment later.
      var runs = ok(await repo.fetchRuns(owner, name, w.id));
      for (var i = 0; i < 20 && runs.length <= before; i++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        runs = ok(await repo.fetchRuns(owner, name, w.id));
      }
      expect(runs.length, greaterThan(before));
      final run = runs.first;
      expect(run.event, 'workflow_dispatch');

      // Wait for it to finish, then read jobs and a job log.
      var current = ok(await repo.fetchRun(owner, name, run.id));
      for (var i = 0; i < 30 && current.isActive; i++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        current = ok(await repo.fetchRun(owner, name, run.id));
      }
      expect(current.isActive, isFalse);
      final jobs = ok(await repo.fetchJobs(owner, name, run.id));
      expect(jobs, isNotEmpty);
      expect(jobs.first.steps.length, greaterThanOrEqualTo(2));
      final log = ok(await repo.fetchJobLog(owner, name, jobs.first.id));
      expect(log, contains('environment=staging'));
      expect(log, contains('note=live test'));
      ok(await repo.fetchRepoRuns(owner, name));
    },
    skip: skip,
  );

  test('dispatch to a workflow without inputs works bare, and is rejected '
      'with the explanation if inputs are sent', () async {
    final w = ok(
      await repo.fetchWorkflows(owner, name),
    ).firstWhere((w) => w.name == 'No inputs');
    ok(await repo.triggerRun(owner, name, w.id, ref: 'main'));

    final rejected = await repo.triggerRun(
      owner,
      name,
      w.id,
      ref: 'main',
      inputs: {'surprise': 'x'},
    );
    final failure = (rejected as Err<void, AppFailure>).error;
    expect(failure, isA<DispatchRejectedFailure>());
    expect(failure.message, contains('GitHub'));
  }, skip: skip);

  test('a disabled workflow cannot be dispatched, and says so', () async {
    final w = ok(
      await repo.fetchWorkflows(owner, name),
    ).firstWhere((w) => w.name == 'Disabled one');
    final result = await repo.triggerRun(owner, name, w.id, ref: 'main');
    final failure = (result as Err<void, AppFailure>).error;
    // ignore: avoid_print
    print('disabled dispatch -> ${failure.runtimeType}: ${failure.message}');
  }, skip: skip);

  test(
    'an invalid token is an auth failure, kept apart from permission',
    () async {
      final bad = GitHubRepositoryImpl(buildGitHubDio(token: 'ghp_invalid'));
      final result = await bad.fetchRepos();
      expect((result as Err).error, isA<AuthFailure>());
    },
    skip: skip,
  );
}
