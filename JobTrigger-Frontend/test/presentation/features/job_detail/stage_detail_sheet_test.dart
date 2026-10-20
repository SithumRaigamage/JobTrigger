import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/presentation/features/job_detail/stage_detail_sheet.dart';

import '../../../support/fake_jenkins_repository.dart';

class _StageRepository extends FakeJenkinsRepository {
  _StageRepository(this.steps);

  final Map<String, List<PipelineStep>?> steps;

  @override
  Future<Result<List<PipelineStep>?, AppFailure>> fetchStageSteps(
    String buildUrl,
    String stageId,
  ) async => Ok(steps[stageId]);

  @override
  Future<Result<StepLog, AppFailure>> fetchStepLog(
    String buildUrl,
    String stepId,
  ) async =>
      Ok(StepLog(text: 'log of $stepId\n', hasMore: stepId == 'truncated'));
}

Future<void> _pump(
  WidgetTester tester,
  StageNode node,
  Map<String, List<PipelineStep>?> steps, {
  VoidCallback? onViewFullLog,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        jenkinsRepositoryProvider.overrideWithValue(_StageRepository(steps)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: StageDetailSheet(
            buildUrl: 'https://ci.test/job/p/5/',
            node: node,
            onViewFullLog: onViewFullLog,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const echo = PipelineStep(id: 'ok', name: 'Print Message', status: 'SUCCESS');
  const boom = PipelineStep(
    id: 'boom',
    name: 'Error signal',
    status: 'FAILED',
    description: 'suite failed',
  );

  testWidgets('the first failed step opens itself and shows its log', (
    tester,
  ) async {
    await _pump(
      tester,
      const StageNode(
        PipelineStage(
          id: 'integration',
          name: 'Integration',
          status: 'FAILED',
          errorMessage: 'Fixture: integration suite failed',
        ),
      ),
      {
        'integration': [echo, boom],
      },
    );

    expect(find.text('Fixture: integration suite failed'), findsOneWidget);
    expect(find.text('log of boom'), findsOneWidget);
    // The passing step stays collapsed.
    expect(find.text('log of ok'), findsNothing);
  });

  testWidgets('a parallel stage lists each branch with its own steps', (
    tester,
  ) async {
    await _pump(
      tester,
      const StageNode(
        PipelineStage(id: 'test', name: 'Test', status: 'SUCCESS'),
        [
          PipelineStage(id: 'unit', name: 'Unit', status: 'SUCCESS'),
          PipelineStage(id: 'int', name: 'Integration', status: 'FAILED'),
        ],
      ),
      {
        'unit': [echo],
        'int': [boom],
      },
    );

    expect(find.text('Unit'), findsOneWidget);
    expect(find.text('Integration'), findsOneWidget);
    // The group shows the worst branch status, not Jenkins' SUCCESS.
    expect(find.text('FAILED'), findsOneWidget);
    expect(find.text('log of boom'), findsOneWidget);
  });

  testWidgets('without step details it points to the full log', (tester) async {
    var opened = 0;
    await _pump(
      tester,
      const StageNode(PipelineStage(id: 'x', name: 'Build', status: 'SUCCESS')),
      {'x': null},
      onViewFullLog: () => opened++,
    );

    expect(
      find.text("Step details aren't available on this server."),
      findsOneWidget,
    );
    await tester.tap(find.text('View full log'));
    expect(opened, 1);
  });

  testWidgets('a truncated step log offers the full console', (tester) async {
    await _pump(
      tester,
      const StageNode(PipelineStage(id: 's', name: 'Build', status: 'FAILED')),
      {
        's': [
          const PipelineStep(id: 'truncated', name: 'Shell', status: 'FAILED'),
        ],
      },
      onViewFullLog: () {},
    );

    expect(find.text('Truncated — view full log'), findsOneWidget);
  });
}
