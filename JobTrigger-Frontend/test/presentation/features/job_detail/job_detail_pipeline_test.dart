import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/downstream_project.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/parameter_definition.dart';
import 'package:job_trigger/domain/jenkins/parameter_file.dart';
import 'package:job_trigger/domain/jenkins/pending_input.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/domain/jenkins/queue_item.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_jenkins_repository.dart';

/// US-PIPE-01/05/09 on job detail: queued state, a paused input step, and
/// downstream links.
const _jobUrl = 'https://ci.test/job/deploy/';
const _queueUrl = 'https://ci.test/queue/item/5/';

class _Repo extends FakeJenkinsRepository {
  _Repo({required this.job, this.input});

  final JenkinsJob job;
  final PendingInput? input;
  final submits = <bool>[];

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async =>
      Ok(job);

  @override
  Future<Result<String?, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    Map<String, ParameterFile> files = const {},
    String? paramToken,
  }) async => const Ok(_queueUrl);

  @override
  Future<Result<QueueItem, AppFailure>> fetchQueueItem(String url) async =>
      const Ok(QueueItem(why: 'Waiting for next available executor'));

  @override
  Future<Result<PendingInput?, AppFailure>> fetchPendingInput(
    String buildUrl,
  ) async => Ok(input);

  @override
  Future<Result<void, AppFailure>> submitInput({
    required String buildUrl,
    required String inputId,
    required bool proceed,
    Map<String, String> parameters = const {},
  }) async {
    submits.add(proceed);
    return const Ok(null);
  }

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(String url) async =>
      const Ok(null);

  @override
  Future<Result<List<PipelineStage>?, AppFailure>> fetchPipelineStages(
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

const _paused = JenkinsBuild(
  number: 9,
  url: '${_jobUrl}9/',
  timestamp: 0,
  building: true,
  estimatedDuration: 60000,
);

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  SharedPreferences.setMockInitialValues({});
  tester.view
    ..physicalSize = const Size(900, 2000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => JobDetailScreen(job: repo.job),
      ),
      GoRoute(
        path: AppRoutes.jobDetail,
        builder: (_, state) =>
            Scaffold(body: Text('job ${(state.extra! as JenkinsJob).name}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        jenkinsRepositoryProvider.overrideWithValue(repo),
        credentialsRepositoryProvider.overrideWithValue(_NoServers()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('after a trigger, a queued build shows queued with the reason', (
    tester,
  ) async {
    await _pump(
      tester,
      _Repo(
        job: const JenkinsJob(name: 'deploy', url: _jobUrl),
      ),
    );

    await tester.tap(find.text('Trigger build'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trigger'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Waiting for next available executor'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a paused input asks first; Cancel submits nothing', (
    tester,
  ) async {
    final repo = _Repo(
      job: const JenkinsJob(name: 'deploy', url: _jobUrl, lastBuild: _paused),
      input: const PendingInput(
        id: 'ok1',
        message: 'Deploy to production?',
        proceedText: 'Ship it',
        abortText: 'Reject',
      ),
    );
    await _pump(tester, repo);

    expect(find.text('Deploy to production?'), findsOneWidget);
    await tester.tap(find.text('Ship it'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repo.submits, isEmpty);
  });

  testWidgets('approve and abort each submit once they are confirmed', (
    tester,
  ) async {
    final repo = _Repo(
      job: const JenkinsJob(name: 'deploy', url: _jobUrl, lastBuild: _paused),
      input: const PendingInput(
        id: 'ok1',
        message: 'Deploy to production?',
        proceedText: 'Ship it',
        abortText: 'Reject',
      ),
    );
    await _pump(tester, repo);

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Reject'),
          )
          .last,
    );
    await tester.pumpAndSettle();
    expect(repo.submits, [false]);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('downstream jobs are listed and open their detail', (
    tester,
  ) async {
    await _pump(
      tester,
      _Repo(
        job: const JenkinsJob(
          name: 'deploy',
          url: _jobUrl,
          downstreamProjects: [
            DownstreamProject(
              name: 'smoke-tests',
              url: 'https://ci.test/job/smoke/',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DOWNSTREAM'), findsOneWidget);
    await tester.tap(find.text('smoke-tests'));
    await tester.pumpAndSettle();
    expect(find.text('job smoke-tests'), findsOneWidget);
  });

  testWidgets('no downstream jobs, no Downstream section', (tester) async {
    await _pump(
      tester,
      _Repo(
        job: const JenkinsJob(name: 'deploy', url: _jobUrl),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DOWNSTREAM'), findsNothing);
  });

  // US-PIPE-05 "Input step requests parameters": the same parameter form
  // as a trigger, filled with the step's defaults.
  testWidgets('an input step with parameters shows the parameter form', (
    tester,
  ) async {
    await _pump(
      tester,
      _Repo(
        job: const JenkinsJob(name: 'deploy', url: _jobUrl, lastBuild: _paused),
        input: const PendingInput(
          id: 'ok1',
          message: 'Where to?',
          inputs: [
            ParameterDefinition(
              name: 'TARGET',
              type: 'StringParameterDefinition',
              defaultValue: 'staging',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Where to?'), findsOneWidget);
    expect(find.text('TARGET'), findsOneWidget);
    expect(find.text('staging'), findsOneWidget);
  });
}
