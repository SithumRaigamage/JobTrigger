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
import 'package:job_trigger/domain/jenkins/pending_input.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_jenkins_repository.dart';

const _url = 'https://jenkins.test/job/api/';

class _Repo extends FakeJenkinsRepository {
  _Repo(this.job);

  final JenkinsJob job;

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async =>
      Ok(job);

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

class _NoServers implements CredentialsRepository {
  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      const Ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

JenkinsBuild _build(int number, String result) => JenkinsBuild(
  number: number,
  url: '$_url$number/',
  result: result,
  timestamp: DateTime.now()
      .subtract(const Duration(hours: 2))
      .millisecondsSinceEpoch
      .toDouble(),
);

Future<void> _pump(WidgetTester tester, JenkinsJob job) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        jenkinsRepositoryProvider.overrideWithValue(_Repo(job)),
        credentialsRepositoryProvider.overrideWithValue(_NoServers()),
      ],
      child: MaterialApp(home: JobDetailScreen(job: job)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('links to the last success and last failure (US-JX-05)', (
    tester,
  ) async {
    await _pump(
      tester,
      JenkinsJob(
        name: 'api',
        url: _url,
        lastBuild: _build(12, 'FAILURE'),
        lastSuccessfulBuild: _build(9, 'SUCCESS'),
        lastFailedBuild: _build(12, 'FAILURE'),
      ),
    );

    expect(find.text('Last success #9 · 2h ago'), findsOneWidget);
    // The last failure *is* the last build: no redundant chip.
    expect(find.textContaining('Last failure'), findsNothing);
  });
}
