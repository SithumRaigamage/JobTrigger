import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/features/build_detail/build_detail_screen.dart';

import '../../../support/fake_jenkins_repository.dart';

const _url = 'https://ci.test/job/api/7/';

class _Repo extends FakeJenkinsRepository {
  bool keep = false;
  String description = '<b>Release</b> 1.4 &amp; hotfix';
  int toggles = 0;
  String? savedDescription;

  @override
  Future<Result<JenkinsBuild, AppFailure>> fetchBuildDetail(String url) async =>
      Ok(
        JenkinsBuild(
          number: 7,
          url: _url,
          result: 'SUCCESS',
          timestamp: 0,
          duration: 252000,
          keepLog: keep,
          description: description,
          causes: const ['Started by user admin'],
          parameterValues: const {'BRANCH': 'main'},
        ),
      );

  @override
  Future<Result<void, AppFailure>> toggleKeepLog(String buildUrl) async {
    toggles++;
    keep = !keep;
    return const Ok(null);
  }

  @override
  Future<Result<void, AppFailure>> setBuildDescription(
    String buildUrl,
    String description,
  ) async {
    savedDescription = description;
    this.description = description;
    return const Ok(null);
  }

  @override
  Future<Result<List<PipelineStage>?, AppFailure>> fetchPipelineStages(
    String buildUrl,
  ) async => const Ok(null);

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(
    String buildUrl,
  ) async => const Ok(null);
}

Future<_Repo> _pump(WidgetTester tester) async {
  final repo = _Repo();
  tester.view
    ..physicalSize = const Size(900, 1800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        home: BuildDetailScreen(
          jenkinsBuild: JenkinsBuild(number: 7, url: _url, timestamp: 0),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('shows the build, with the description as plain text', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('SUCCESS'), findsOneWidget);
    expect(find.textContaining('took 4m 12s'), findsOneWidget);
    expect(find.text('Started by user admin'), findsOneWidget);
    expect(find.text('BRANCH: main'), findsOneWidget);
    // HTML is never rendered: tags gone, entities decoded.
    expect(find.text('Release 1.4 & hotfix'), findsOneWidget);
    expect(find.textContaining('<b>'), findsNothing);
  });

  testWidgets('keep forever asks, toggles, and re-reads the server', (
    tester,
  ) async {
    final repo = await _pump(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Keep forever?'), findsOneWidget);
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();

    expect(repo.toggles, 1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text('Exempt from log rotation'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // toast auto-dismiss
  });

  testWidgets('the description can be edited', (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.byTooltip('Edit description'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Shipped to prod');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.savedDescription, 'Shipped to prod');
    expect(find.text('Shipped to prod'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
