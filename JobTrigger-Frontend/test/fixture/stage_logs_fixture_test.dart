@Tags(['fixture'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';

import 'fixture_support.dart';

/// P11-08 / US-JX-04 against `pipeline-stages` (a parallel Test stage whose
/// Integration branch fails).
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();

  test(
    'groups the real parallel stages and reaches the failing step log',
    () async {
      final repository = jenkins.adminRepository();
      final build = await triggerAndAwaitStart(jenkins, 'pipeline-stages');
      await awaitCompletion(jenkins, 'pipeline-stages', build.number);

      final stages = expectOk(await repository.fetchPipelineStages(build.url))!;
      final nodes = groupParallelStages(stages);
      final test = nodes.singleWhere((node) => node.stage.name == 'Test');
      expect(test.branches.map((b) => b.name), ['Unit', 'Integration']);
      expect(test.status, 'FAILED');

      final integration = test.branches.singleWhere(
        (b) => b.name == 'Integration',
      );
      expect(integration.errorMessage, 'Fixture: integration suite failed');

      final steps = expectOk(
        await repository.fetchStageSteps(build.url, integration.id),
      )!;
      expect(steps.any((step) => step.isFailed), isTrue);

      final echo = steps.firstWhere((step) => step.name == 'Print Message');
      final log = expectOk(await repository.fetchStepLog(build.url, echo.id));
      expect(log.text, contains('Running integration tests'));
    },
  );
}
