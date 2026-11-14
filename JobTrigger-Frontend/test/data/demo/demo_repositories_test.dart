import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/demo/demo_account_repositories.dart';
import 'package:job_trigger/data/demo/demo_github_repository.dart';
import 'package:job_trigger/data/demo/demo_sonarqube_repository.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';

/// E2 (PE-10): the demo's GitHub, SonarQube and account repositories.
void main() {
  final now = DateTime(2026, 11, 14, 12);

  T ok<T>(Result<T, AppFailure> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final error) => fail('expected Ok, got $error'),
  };

  group('GitHub', () {
    final repo = DemoGitHubRepository(clock: () => now);

    test('lists repositories, workflows and runs, newest first', () async {
      expect(ok(await repo.fetchRepos()).map((r) => r.name), ['app', 'infra']);
      final workflows = ok(await repo.fetchWorkflows('demo-org', 'app'));
      expect(workflows.map((w) => w.name), ['CI', 'Deploy']);
      final runs = ok(await repo.fetchRuns('demo-org', 'app', 501));
      expect(runs.first.isActive, isTrue);
      expect(runs.map((r) => r.conclusion), contains('failure'));
    });

    test('a failed run has jobs, steps and a log', () async {
      final jobs = ok(await repo.fetchJobs('demo-org', 'app', 9003));
      expect(jobs.single.steps.any((s) => s.conclusion == 'failure'), isTrue);
      final log = ok(await repo.fetchJobLog('demo-org', 'app', jobs.single.id));
      expect(log, contains('exit code 1'));
    });

    test('trigger and cancel are not available in demo', () async {
      final trigger = await repo.triggerRun(
        'demo-org',
        'app',
        502,
        ref: 'main',
      );
      final cancel = await repo.cancelRun('demo-org', 'app', 9005);
      expect((trigger as Err).error, isA<DemoUnavailableFailure>());
      expect((cancel as Err).error, isA<DemoUnavailableFailure>());
    });
  });

  group('SonarQube', () {
    final repo = DemoSonarQubeRepository(clock: () => now);

    test('one project fails its quality gate, one passes', () async {
      final projects = ok(await repo.fetchProjects()).projects;
      expect(projects, hasLength(2));
      final failing = ok(await repo.fetchQualityGate(projects.first.key));
      expect(failing.state, QualityGateState.failed);
      expect(failing.failing, isNotEmpty);
      final passing = ok(await repo.fetchQualityGate(projects.last.key));
      expect(passing.state, QualityGateState.passed);
    });

    test('measures, filtered issues and analyses', () async {
      final key = ok(await repo.fetchProjects()).projects.first.key;
      expect(ok(await repo.fetchMeasures(key))['coverage'], '62.3');
      final all = ok(await repo.fetchIssues(key));
      expect(all.total, 5);
      final bugs = ok(
        await repo.fetchIssues(
          key,
          filter: const SonarQubeIssueFilter(types: {'BUG'}),
        ),
      );
      expect(bugs.issues.single.type, 'BUG');
      expect(ok(await repo.fetchAnalysisHistory(key)), hasLength(3));
    });
  });

  group('account', () {
    test('lists one sample credential and refuses every change', () async {
      expect(ok(await DemoCredentialsRepository().fetchAll()), hasLength(1));
      final add = await DemoCredentialsRepository().add(
        serverName: 's',
        jenkinsURL: 'https://x',
        username: 'u',
        secret: 's',
      );
      expect((add as Err).error, isA<DemoUnavailableFailure>());
      final login = await DemoAuthRepository().login(email: 'a', password: 'b');
      expect((login as Err).error, isA<DemoUnavailableFailure>());
      expect(
        (await DemoAuthRepository().deleteAccount(password: 'p') as Err).error,
        isA<DemoUnavailableFailure>(),
      );
    });
  });
}
