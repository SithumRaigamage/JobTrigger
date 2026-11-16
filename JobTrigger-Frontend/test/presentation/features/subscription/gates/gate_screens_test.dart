import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/notification_service.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/build_watch.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/jenkins_view.dart';
import 'package:job_trigger/domain/jenkins/pending_input.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/features/home/home_screen.dart';
import 'package:job_trigger/presentation/features/home/reachability_watcher.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_screen.dart';
import 'package:job_trigger/presentation/features/notifications/background_watch.dart';
import 'package:job_trigger/presentation/features/notifications/build_watch_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/plan_gate.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fake_jenkins_repository.dart';
import '../../../../support/plan_gates.dart';

/// P20-25: the real Jenkins screens open the paywall with the matching
/// reason when the plan blocks them, and behave as before when it doesn't.
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
const _views = [
  JenkinsView(name: 'all', url: 'https://ci.test/', isPrimary: true),
  JenkinsView(name: 'Pipelines', url: 'https://ci.test/view/Pipelines/'),
];

class _Repo extends FakeJenkinsRepository {
  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async =>
      const Ok(_job);

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(
    String? folderUrl,
  ) async => const Ok([_job]);

  @override
  Future<Result<List<JenkinsView>, AppFailure>> fetchViews() async =>
      const Ok(_views);

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
  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> show(BuildNotification notification) async {}
}

class _Scheduler implements BackgroundWatchScheduler {
  @override
  bool get isSupported => true;

  @override
  Future<void> sync({required bool hasWatches}) async {}
}

/// Three pins already on this server: Free's whole allowance.
void _threePins() => SharedPreferences.setMockInitialValues({
  'pinned_jobs_s1': jsonEncode([
    for (final n in ['x', 'y', 'z'])
      {'url': 'https://ci.test/job/$n/', 'label': n},
  ]),
});

Future<void> _pump(WidgetTester tester, Widget screen, PlanGate gate) async {
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (_, state) => Scaffold(
          body: Text('paywall:${state.uri.queryParameters['reason']}'),
        ),
      ),
      GoRoute(
        path: AppRoutes.jobDetail,
        builder: (_, _) => const Scaffold(body: Text('detail')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        gateOverride(gate),
        jenkinsRepositoryProvider.overrideWithValue(_Repo()),
        activeServerNotifierProvider.overrideWith(_Server.new),
        notificationServiceProvider.overrideWithValue(_Notifications()),
        backgroundWatchSchedulerProvider.overrideWithValue(_Scheduler()),
        reachabilityWatcherProvider.overrideWith((ref) {}),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('job detail', () {
    testWidgets('Free: the pin button opens maxPinnedJobs at the 4th pin', (
      tester,
    ) async {
      _threePins();
      await _pump(tester, const JobDetailScreen(job: _job), freeGate);
      await tester.tap(find.byTooltip('Pin to Home'));
      await tester.pumpAndSettle();
      expect(find.text('paywall:maxPinnedJobs'), findsOneWidget);
    });

    testWidgets('Pro: the pin button pins as before', (tester) async {
      _threePins();
      await _pump(tester, const JobDetailScreen(job: _job), proGate);
      await tester.tap(find.byTooltip('Pin to Home'));
      await tester.pumpAndSettle();
      expect(find.textContaining('paywall:'), findsNothing);
      expect(find.byTooltip('Unpin from Home'), findsOneWidget);
    });

    testWidgets('Free: "Notify for every build" opens backgroundWatch before '
        'any explanation or permission prompt', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pump(tester, const JobDetailScreen(job: _job), freeGate);
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notify for every build'));
      await tester.pumpAndSettle();
      expect(find.text('paywall:backgroundWatch'), findsOneWidget);
      expect(find.text('Build notifications'), findsNothing);
    });

    testWidgets('Pro: "Notify for every build" asks as before', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pump(tester, const JobDetailScreen(job: _job), proGate);
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notify for every build'));
      await tester.pumpAndSettle();
      expect(find.text('Build notifications'), findsOneWidget);
    });
  });

  group('home', () {
    testWidgets('Free: long-press pinning opens maxPinnedJobs at the 4th', (
      tester,
    ) async {
      _threePins();
      await _pump(tester, const HomeScreen(), freeGate);
      await tester.longPress(find.text('api'));
      await tester.pumpAndSettle();
      expect(find.text('paywall:maxPinnedJobs'), findsOneWidget);
    });

    testWidgets('Pro: long-press pins as before', (tester) async {
      _threePins();
      await _pump(tester, const HomeScreen(), proGate);
      await tester.longPress(find.text('api'));
      await tester.pumpAndSettle();
      expect(find.text('Pinned api'), findsOneWidget);
    });

    testWidgets('Free: the view picker opens insights', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pump(tester, const HomeScreen(), freeGate);
      await tester.tap(find.text('All jobs'));
      await tester.pumpAndSettle();
      expect(find.text('paywall:insights'), findsOneWidget);
    });

    testWidgets('Pro: the view picker lists the views as before', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await _pump(tester, const HomeScreen(), proGate);
      await tester.tap(find.text('All jobs'));
      await tester.pumpAndSettle();
      expect(find.text('Pipelines'), findsOneWidget);
    });
  });
}
