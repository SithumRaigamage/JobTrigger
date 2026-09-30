import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/notification_service.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/build_watch.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/pending_input.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_screen.dart';
import 'package:job_trigger/presentation/features/notifications/background_watch.dart';
import 'package:job_trigger/presentation/features/notifications/build_watch_notifier.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_jenkins_repository.dart';

const _url = 'https://ci.test/job/api/';
const _job = JenkinsJob(
  name: 'api',
  url: _url,
  lastBuild: JenkinsBuild(
    number: 9,
    url: '${_url}9/',
    result: 'SUCCESS',
    building: false,
    timestamp: 0,
    duration: 0,
  ),
);

class _Repo extends FakeJenkinsRepository {
  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async =>
      const Ok(_job);

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(String b) async =>
      const Ok(null);

  @override
  Future<Result<List<PipelineStage>?, AppFailure>> fetchPipelineStages(
    String b,
  ) async => const Ok(null);

  @override
  Future<Result<PendingInput?, AppFailure>> fetchPendingInput(String b) async =>
      const Ok(null);
}

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 's1',
    serverName: 's1',
    jenkinsURL: 'https://ci.test',
    username: 'u',
    secret: 's',
  );
}

class _Notifications implements NotificationService {
  _Notifications({required this.granted});

  final bool granted;

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<void> show(BuildNotification notification) async {}
}

class _Scheduler implements BackgroundWatchScheduler {
  @override
  Future<void> sync({required bool hasWatches}) async {}
}

void main() {
  Future<void> pumpScreen(WidgetTester tester, {bool granted = true}) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jenkinsRepositoryProvider.overrideWithValue(_Repo()),
          activeServerNotifierProvider.overrideWith(_Server.new),
          notificationServiceProvider.overrideWithValue(
            _Notifications(granted: granted),
          ),
          backgroundWatchSchedulerProvider.overrideWithValue(_Scheduler()),
        ],
        child: const MaterialApp(home: JobDetailScreen(job: _job)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooseWatchJob(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notify for every build'));
    await tester.pumpAndSettle();
    // First watch: the rationale comes before the OS prompt.
    expect(find.text('Build notifications'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    // Disposes the scope, cancelling the watch timer.
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('watching a job confirms it and lights the bell (US-JX-10)', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);

    await chooseWatchJob(tester);

    expect(
      find.text("You'll be notified when builds of api finish."),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop notifying for this job'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a denied permission explains where to turn it on', (
    tester,
  ) async {
    await pumpScreen(tester, granted: false);
    await chooseWatchJob(tester);

    expect(
      find.textContaining('Notifications are off for JobTrigger'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    await unmount(tester);
  });
}
