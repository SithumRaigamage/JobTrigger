import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/parameter_file.dart';
import 'package:job_trigger/domain/jenkins/job_property.dart';
import 'package:job_trigger/domain/jenkins/parameter_definition.dart';
import 'package:job_trigger/domain/jenkins/pending_input.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../support/fake_jenkins_repository.dart';

const _jobUrl = 'https://jenkins.test/job/deploy/';

/// A building job with a normal and a secret parameter.
const _job = JenkinsJob(
  name: 'deploy',
  url: _jobUrl,
  lastBuild: JenkinsBuild(
    number: 7,
    url: '${_jobUrl}7/',
    timestamp: 0,
    building: true,
  ),
  property: [
    JobProperty(
      parameterDefinitions: [
        ParameterDefinition(
          name: 'BRANCH',
          type: 'StringParameterDefinition',
          defaultValue: 'main',
        ),
        ParameterDefinition(
          name: 'DEPLOY_TOKEN',
          type: 'PasswordParameterDefinition',
        ),
      ],
    ),
  ],
);

class _RecordingRepository extends FakeJenkinsRepository {
  int triggerCalls = 0;
  int cancelCalls = 0;

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async =>
      const Ok(_job);

  @override
  Future<Result<String?, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    Map<String, ParameterFile> files = const {},
    String? paramToken,
  }) async {
    triggerCalls++;
    return const Ok(null);
  }

  @override
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl) async {
    cancelCalls++;
    return const Ok(null);
  }

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(
    String buildUrl,
  ) async => const Ok(null);

  @override
  Future<Result<List<PipelineStage>?, AppFailure>> fetchPipelineStages(
    String buildUrl,
  ) async => const Ok(null);

  @override
  Future<Result<PendingInput?, AppFailure>> fetchPendingInput(
    String buildUrl,
  ) async => const Ok(null);
}

class _NoServersRepository implements CredentialsRepository {
  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      const Ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<_RecordingRepository> _pumpScreen(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final repository = _RecordingRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        jenkinsRepositoryProvider.overrideWithValue(repository),
        credentialsRepositoryProvider.overrideWithValue(_NoServersRepository()),
      ],
      child: const MaterialApp(home: JobDetailScreen(job: _job)),
    ),
  );
  await tester.pump();
  await tester.pump();
  return repository;
}

void main() {
  group('AUD-08: trigger and cancel require confirmation', () {
    testWidgets('dismissing the trigger confirmation never calls Jenkins', (
      tester,
    ) async {
      final repository = await _pumpScreen(tester);

      await tester.tap(find.text('Trigger Build'));
      await tester.pumpAndSettle();
      expect(find.text('Trigger build?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repository.triggerCalls, 0);
    });

    testWidgets('confirming triggers exactly once', (tester) async {
      final repository = await _pumpScreen(tester);

      await tester.tap(find.text('Trigger Build'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(repository.triggerCalls, 1);
    });

    testWidgets('the summary shows parameters with the secret masked', (
      tester,
    ) async {
      await _pumpScreen(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'DEPLOY_TOKEN'),
        'top-secret',
      );

      await tester.tap(find.text('Trigger Build'));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.textContaining('main')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.textContaining('••••')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.textContaining('top-secret'),
        ),
        findsNothing,
      );
    });

    testWidgets('cancel asks first, and dismissing keeps the build running', (
      tester,
    ) async {
      final repository = await _pumpScreen(tester);

      await tester.tap(find.text('Cancel Build'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel build #7?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repository.cancelCalls, 0);

      await tester.tap(find.text('Cancel Build'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel build'));
      await tester.pumpAndSettle();
      expect(repository.cancelCalls, 1);
    });
  });

  testWidgets(
    'shows last success/failure links only when they differ (US-JX-05)',
    (tester) async {
      await _pumpScreen(tester);
      // `_job`'s last build is #7 and has no success/failure links.
      expect(find.textContaining('Last success'), findsNothing);
      expect(find.textContaining('Last failure'), findsNothing);
    },
  );
}
