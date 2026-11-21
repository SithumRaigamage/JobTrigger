import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/health_report.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/parameter_file.dart';
import 'package:job_trigger/domain/jenkins/pending_input.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_jenkins_repository.dart';

/// US-JOB-01/02/04: job detail states.
const _jobUrl = 'https://jenkins.test/job/deploy/';

JenkinsJob _job({JenkinsBuild? lastBuild}) =>
    JenkinsJob(name: 'deploy', url: _jobUrl, lastBuild: lastBuild);

JenkinsBuild _building({double? estimatedDuration}) => JenkinsBuild(
  number: 12,
  url: '${_jobUrl}12/',
  timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
  building: true,
  estimatedDuration: estimatedDuration,
);

/// Answers `fetchJobDetail` from [results] in order, repeating the last.
class _Repo extends FakeJenkinsRepository {
  _Repo(this.results);

  final List<Result<JenkinsJob, AppFailure>> results;
  int fetches = 0;
  int triggers = 0;
  Completer<Result<String?, AppFailure>>? pendingTrigger;

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async =>
      results[fetches++ < results.length ? fetches - 1 : results.length - 1];

  @override
  Future<Result<String?, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    Map<String, ParameterFile> files = const {},
    String? paramToken,
  }) {
    triggers++;
    return (pendingTrigger ??= Completer()).future;
  }

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(String url) async =>
      const Ok(null);

  @override
  Future<Result<List<PipelineStage>?, AppFailure>> fetchPipelineStages(
    String url,
  ) async => const Ok(null);

  @override
  Future<Result<PendingInput?, AppFailure>> fetchPendingInput(
    String url,
  ) async => const Ok(null);
}

class _NoServers implements CredentialsRepository {
  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      const Ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        jenkinsRepositoryProvider.overrideWithValue(repo),
        credentialsRepositoryProvider.overrideWithValue(_NoServers()),
      ],
      child: MaterialApp(home: JobDetailScreen(job: _job())),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('a job that never ran says "No builds yet", not an error', (
    tester,
  ) async {
    await _pump(tester, _Repo([Ok(_job())]));
    await tester.pumpAndSettle();

    expect(find.text('No builds yet'), findsOneWidget);
    expect(find.text('Retry Connection'), findsNothing);
  });

  testWidgets('a deleted job says it may have been removed, with Retry', (
    tester,
  ) async {
    await _pump(tester, _Repo([const Err(NotFoundFailure())]));
    await tester.pumpAndSettle();

    expect(find.text(const NotFoundFailure().message), findsOneWidget);
    expect(find.text('Retry Connection'), findsOneWidget);
  });

  testWidgets('a failed poll keeps the last status and polls again', (
    tester,
  ) async {
    final repo = _Repo([
      Ok(_job(lastBuild: _building(estimatedDuration: 600000.0))),
      const Err(ServerFailure(500)),
      Ok(_job(lastBuild: _building(estimatedDuration: 600000.0))),
    ]);
    await _pump(tester, repo);
    // The running build's card, with its progress bar.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(repo.fetches, 2);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Retry Connection'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(repo.fetches, 3);
  });

  testWidgets('no estimated duration shows an indeterminate bar', (
    tester,
  ) async {
    await _pump(tester, _Repo([Ok(_job(lastBuild: _building()))]));

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, isNull);
  });

  testWidgets('with an estimate the bar shows the fraction done', (
    tester,
  ) async {
    await _pump(
      tester,
      _Repo([Ok(_job(lastBuild: _building(estimatedDuration: 600000.0)))]),
    );

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, isNotNull);
  });

  testWidgets('Trigger is off while a trigger is in flight', (tester) async {
    final repo = _Repo([Ok(_job())]);
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trigger build'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trigger'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Triggering…'), findsOneWidget);
    await tester.tap(find.text('Triggering…'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Trigger build?'), findsNothing);
    expect(repo.triggers, 1);

    repo.pendingTrigger!.complete(const Ok(null));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('shows the description, health and last build', (tester) async {
    const job = JenkinsJob(
      name: 'deploy',
      url: _jobUrl,
      description: 'Ships the API',
      healthReport: [HealthReport(description: 'Build stability', score: 80)],
      lastBuild: JenkinsBuild(
        number: 41,
        url: '${_jobUrl}41/',
        timestamp: 0,
        result: 'SUCCESS',
        duration: 5000,
      ),
    );
    await _pump(tester, _Repo([const Ok(job)]));
    await tester.pumpAndSettle();

    expect(find.text('Ships the API'), findsOneWidget);
    expect(find.text('Build stability (80%)'), findsOneWidget);
    expect(find.textContaining('#41'), findsOneWidget);
    expect(find.byTooltip('History'), findsOneWidget);
  });
}
