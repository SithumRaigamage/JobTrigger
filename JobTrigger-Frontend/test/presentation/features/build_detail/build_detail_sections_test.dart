import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/build_artifact.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/domain/jenkins/scm_change.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/domain/jenkins/upstream_cause.dart';
import 'package:job_trigger/presentation/features/build_detail/build_detail_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';

import '../../../support/fake_jenkins_repository.dart';

/// US-PIPE-02/03/06/07/09: the additive sections of a build: shown with
/// data, absent without it, and never blocking the screen when they fail.
const _url = 'https://ci.test/job/api/7/';

const _rich = JenkinsBuild(
  number: 7,
  url: _url,
  result: 'FAILURE',
  timestamp: 0,
  duration: 1000,
  causes: ['Started by user Sam Lee', 'Started by timer'],
  upstreamCause: UpstreamCause(
    projectName: 'libs-core',
    url: 'https://ci.test/job/libs-core/',
  ),
  changes: [
    ScmChange(author: 'sam', message: 'Fix the login retry'),
    ScmChange(author: 'kim', message: 'Bump the SDK'),
  ],
  artifacts: [BuildArtifact(fileName: 'app.apk', relativePath: 'out/app.apk')],
);

const _bare = JenkinsBuild(
  number: 7,
  url: _url,
  result: 'SUCCESS',
  timestamp: 0,
  duration: 1000,
);

class _Repo extends FakeJenkinsRepository {
  _Repo(this.build, {this.report = const Ok(null), this.stages});

  final JenkinsBuild build;
  final Result<TestReport?, AppFailure> report;
  final Result<List<PipelineStage>?, AppFailure>? stages;

  @override
  Future<Result<JenkinsBuild, AppFailure>> fetchBuildDetail(String url) async =>
      Ok(build);

  @override
  Future<Result<List<PipelineStage>?, AppFailure>> fetchPipelineStages(
    String buildUrl,
  ) async => stages ?? const Ok(null);

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(
    String buildUrl,
  ) async => report;
}

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  tester.view
    ..physicalSize = const Size(900, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: BuildDetailScreen(
          jenkinsBuild: JenkinsBuild(number: 7, url: _url, timestamp: 0),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a build with data shows cause, upstream, changes, tests and '
      'artifacts', (tester) async {
    await _pump(
      tester,
      _Repo(
        _rich,
        report: const Ok(TestReport(passCount: 40, failCount: 2, skipCount: 1)),
      ),
    );

    expect(find.text('Triggered by'), findsOneWidget);
    expect(
      find.text('Started by user Sam Lee, Started by timer'),
      findsOneWidget,
    );
    expect(find.text('libs-core'), findsOneWidget);
    expect(find.text('CHANGES'), findsOneWidget);
    expect(find.text('sam: Fix the login retry'), findsOneWidget);
    expect(find.text('kim: Bump the SDK'), findsOneWidget);
    expect(find.textContaining('40 passed · 2 failed'), findsOneWidget);
    expect(find.text('ARTIFACTS'), findsOneWidget);
    expect(find.textContaining('app.apk'), findsWidgets);
  });

  testWidgets('a build without that data shows none of those sections', (
    tester,
  ) async {
    await _pump(tester, _Repo(_bare));

    expect(find.text('Triggered by'), findsNothing);
    expect(find.text('CHANGES'), findsNothing);
    expect(find.text('ARTIFACTS'), findsNothing);
    expect(find.text('PIPELINE'), findsNothing);
    expect(find.textContaining('passed ·'), findsNothing);
    expect(find.text('Console log'), findsOneWidget);
  });

  testWidgets('failed test-report and stage fetches leave the build '
      'readable', (tester) async {
    await _pump(
      tester,
      _Repo(
        _rich,
        report: const Err(ServerFailure(500)),
        stages: const Err(NotFoundFailure()),
      ),
    );

    expect(find.text('Console log'), findsOneWidget);
    expect(find.text('sam: Fix the login retry'), findsOneWidget);
    expect(find.text('Retry Connection'), findsNothing);
    expect(find.text(const ServerFailure(500).message), findsNothing);
  });

  testWidgets('a pipeline build lists its stages with status', (tester) async {
    await _pump(
      tester,
      _Repo(
        _bare,
        stages: const Ok([
          PipelineStage(
            id: '1',
            name: 'Checkout',
            status: 'SUCCESS',
            durationMillis: 4000,
          ),
          PipelineStage(id: '2', name: 'Deploy', status: 'FAILED'),
        ]),
      ),
    );

    expect(find.text('PIPELINE'), findsOneWidget);
    expect(find.textContaining('Checkout'), findsWidgets);
    expect(find.textContaining('Deploy'), findsWidgets);
  });

  // US-PIPE-09 "Upstream link": straight to that job's detail.
  testWidgets('the upstream link opens the upstream job', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const BuildDetailScreen(
            jenkinsBuild: JenkinsBuild(number: 7, url: _url, timestamp: 0),
          ),
        ),
        GoRoute(
          path: AppRoutes.jobDetail,
          builder: (_, state) =>
              Scaffold(body: Text('job ${(state.extra! as JenkinsJob).name}')),
        ),
      ],
    );
    tester.view
      ..physicalSize = const Size(900, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [jenkinsRepositoryProvider.overrideWithValue(_Repo(_rich))],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('libs-core'));
    await tester.pumpAndSettle();
    expect(find.text('job libs-core'), findsOneWidget);
  });
}
