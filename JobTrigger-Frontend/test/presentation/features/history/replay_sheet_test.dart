import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/job_property.dart';
import 'package:job_trigger/domain/jenkins/parameter_definition.dart';
import 'package:job_trigger/domain/jenkins/parameter_file.dart';
import 'package:job_trigger/presentation/features/history/replay_sheet.dart';

import '../../../support/fake_jenkins_repository.dart';

// Widget coverage for the US-PIPE-08 replay sheet (pre-release audit
// 2026-11-20: the reconcile function was tested, the sheet was not).

const _job = JenkinsJob(
  name: 'deploy-api',
  url: 'https://ci.test/job/deploy-api/',
  property: [
    JobProperty(
      parameterDefinitions: [
        ParameterDefinition(
          name: 'ENV',
          type: 'StringParameterDefinition',
          defaultValue: 'staging',
        ),
      ],
    ),
  ],
);

const _build = JenkinsBuild(
  number: 41,
  url: 'https://ci.test/job/deploy-api/41/',
  timestamp: 1793491200000,
  parameterValues: {'ENV': 'production'},
);

class _Repo extends FakeJenkinsRepository {
  final triggered = <Map<String, String>>[];

  @override
  Future<Result<String?, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    Map<String, ParameterFile> files = const {},
    String? paramToken,
  }) async {
    triggered.add(parameters);
    return const Ok(null);
  }
}

Future<_Repo> _pump(WidgetTester tester) async {
  final repo = _Repo();
  tester.view
    ..physicalSize = const Size(900, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ReplaySheet(job: _job, build: _build),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('ReplaySheet (US-PIPE-08)', () {
    testWidgets('is pre-filled with the build\'s recorded values', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Replay #41'), findsOneWidget);
      // The past build's value, not the job's current default.
      expect(find.text('production'), findsOneWidget);
      expect(find.text('staging'), findsNothing);
    });

    testWidgets('Replay triggers with the recorded values and closes', (
      tester,
    ) async {
      final repo = await _pump(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Replay'));
      await tester.pumpAndSettle();

      expect(repo.triggered, [
        {'ENV': 'production'},
      ]);
      expect(find.text('Replay #41'), findsNothing);
      await tester.pump(const Duration(seconds: 4)); // toast
    });

    testWidgets('an edited value is what gets triggered', (tester) async {
      final repo = await _pump(tester);

      await tester.enterText(find.byType(TextField).first, 'canary');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Replay'));
      await tester.pumpAndSettle();

      expect(repo.triggered, [
        {'ENV': 'canary'},
      ]);
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
