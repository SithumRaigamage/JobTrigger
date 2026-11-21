import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/cache/server_safety_store.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/replay_script.dart';
import 'package:job_trigger/domain/safety/server_safety.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/app_lock/app_lock_notifier.dart';
import 'package:job_trigger/presentation/features/history/replay_sheet.dart';
import 'package:job_trigger/presentation/features/replay_edit/replay_edit_notifier.dart';
import 'package:job_trigger/presentation/features/replay_edit/replay_edit_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_jenkins_repository.dart';

// US-JX-16 acceptance criteria AC1, AC3–AC9 (AC2/AC5/AC7 data side:
// test/data/repositories/replay_script_test.dart).

const _pipeline = JenkinsJob(
  name: 'deploy',
  url: 'https://ci.test/job/deploy/',
  jobClass: JenkinsJob.pipelineClass,
);

const _freestyle = JenkinsJob(
  name: 'legacy',
  url: 'https://ci.test/job/legacy/',
  jobClass: 'hudson.model.FreeStyleProject',
);

const _build = JenkinsBuild(
  number: 41,
  url: 'https://ci.test/job/deploy/41/',
  timestamp: 1793491200000,
);

const _script =
    "pipeline { agent any; stages { stage('x') { steps { echo 'hi' } } } }";

class _Repo extends FakeJenkinsRepository {
  _Repo({
    this.script = const Ok(InlineReplayScript(script: _script, sandbox: true)),
    this.history = const [],
  });

  final Result<ReplayScript, AppFailure> script;
  List<JenkinsBuild> history;
  final submitted = <(String, String)>[];
  Result<void, AppFailure> submitResult = const Ok(null);

  @override
  Future<Result<ReplayScript, AppFailure>> fetchReplayScript(
    String jobUrl,
  ) async => script;

  @override
  Future<Result<void, AppFailure>> replayWithScript(
    String buildUrl,
    String script,
  ) async {
    submitted.add((buildUrl, script));
    return submitResult;
  }

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl, {
    int start = 0,
    int count = 25,
  }) async => Ok(history);
}

class _NoServers implements CredentialsRepository {
  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      const Ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _ActiveServer extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 's1',
    serverName: 'Prod CI',
    jenkinsURL: 'https://ci.test',
    username: 'u',
    secret: 's',
  );
}

/// The app lock (US-JX-21) refusing the re-prompt.
class _DenyingLock extends AppLockNotifier {
  final reasons = <String>[];

  @override
  Future<bool> confirmSensitive(String reason) async {
    reasons.add(reason);
    return false;
  }
}

Future<_Repo> _pump(
  WidgetTester tester, {
  _Repo? repo,
  JenkinsBuild build = _build,
  bool readOnly = false,
  _DenyingLock? lock,
}) async {
  SharedPreferences.setMockInitialValues({});
  final repository = repo ?? _Repo();
  tester.view
    ..physicalSize = const Size(900, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/edit',
    routes: [
      GoRoute(
        path: '/edit',
        builder: (_, _) => ReplayEditScreen(job: _pipeline, build: build),
      ),
      GoRoute(
        path: AppRoutes.buildDetail,
        builder: (_, state) =>
            Text('build #${(state.extra! as JenkinsBuild).number}'),
      ),
      GoRoute(
        path: AppRoutes.jobHistory,
        builder: (_, _) => const Text('job history'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        jenkinsRepositoryProvider.overrideWithValue(repository),
        credentialsRepositoryProvider.overrideWithValue(_NoServers()),
        activeServerNotifierProvider.overrideWith(_ActiveServer.new),
        serverSafetyNotifierProvider.overrideWithValue(
          ServerSafety(readOnly: readOnly ? {'jenkins:s1'} : {}),
        ),
        if (lock != null) appLockNotifierProvider.overrideWith(() => lock),
        replayPollingProvider.overrideWithValue(
          const ReplayPolling(
            interval: Duration(milliseconds: 10),
            attempts: 3,
          ),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

/// Confirms both dialogs (AC6), typing the job name in the second.
Future<void> _confirmBoth(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Replay'));
  await tester.pumpAndSettle();
  expect(find.text('Replay #41 with edits?'), findsWidgets);
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  expect(
    find.text('This runs arbitrary pipeline code on Prod CI.'),
    findsOneWidget,
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Confirm name'),
    'deploy',
  );
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Replay').last);
  await tester.pumpAndSettle();
}

void main() {
  group('Replay sheet entry (AC1)', () {
    Future<void> openSheet(WidgetTester tester, JenkinsJob job) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [jenkinsRepositoryProvider.overrideWithValue(_Repo())],
          child: MaterialApp(
            home: Scaffold(
              body: ReplaySheet(job: job, build: _build),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shown for a pipeline job', (tester) async {
      await openSheet(tester, _pipeline);
      expect(find.text('Replay with edits…'), findsOneWidget);
    });

    testWidgets('not shown for a freestyle job', (tester) async {
      await openSheet(tester, _freestyle);
      expect(find.text('Replay with edits…'), findsNothing);
    });
  });

  group('ReplayEditScreen', () {
    testWidgets('loads the script into the editor with its sandbox (AC2)', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Replay #41 with edits'), findsOneWidget);
      expect(find.text('Sandbox'), findsOneWidget);
      final editor = tester.widget<TextField>(
        find.byKey(const ValueKey('replay-script-editor')),
      );
      expect(editor.controller!.text, _script);
    });

    testWidgets('an SCM Jenkinsfile gets a message, no editor (AC3)', (
      tester,
    ) async {
      await _pump(tester, repo: _Repo(script: const Ok(ScmReplayScript())));

      expect(
        find.textContaining('Jenkinsfile comes from a repository'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('replay-script-editor')), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Replay'), findsNothing);
    });

    testWidgets('warns when the build was itself a replay (AC4)', (
      tester,
    ) async {
      await _pump(
        tester,
        build: const JenkinsBuild(
          number: 41,
          url: 'https://ci.test/job/deploy/41/',
          timestamp: 1793491200000,
          causes: ['Replayed #40'],
        ),
      );
      expect(find.textContaining('was itself a replay'), findsOneWidget);
    });

    testWidgets('no warning for an ordinary build (AC4)', (tester) async {
      await _pump(tester);
      expect(find.textContaining('was itself a replay'), findsNothing);
    });

    testWidgets('a 403 on the config says why (AC5)', (tester) async {
      await _pump(tester, repo: _Repo(script: const Err(PermissionFailure())));
      expect(
        find.textContaining("permission to read this job's configuration"),
        findsOneWidget,
      );
    });

    testWidgets('cancelling either confirmation sends nothing (AC6)', (
      tester,
    ) async {
      final repo = await _pump(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Replay'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.submitted, isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, 'Replay'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      // The second dialog stays locked until the job name is typed.
      final locked = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Replay').last,
      );
      expect(locked.onPressed, isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.submitted, isEmpty);
    });

    testWidgets(
      'submits the edited script and opens the new build (AC7, AC8)',
      (tester) async {
        final repo = _Repo(
          history: const [
            JenkinsBuild(
              number: 42,
              url: 'https://ci.test/job/deploy/42/',
              timestamp: 1793491300000,
              causes: ['Replayed #41'],
            ),
          ],
        );
        await _pump(tester, repo: repo);

        await tester.enterText(
          find.byKey(const ValueKey('replay-script-editor')),
          'echo "edited"',
        );
        await _confirmBoth(tester);

        expect(repo.submitted, [
          ('https://ci.test/job/deploy/41/', 'echo "edited"'),
        ]);
        expect(find.text('build #42'), findsOneWidget);
        await tester.pump(const Duration(seconds: 4)); // toast
      },
    );

    testWidgets('an unrelated newer build is not taken for the replay (AC8)', (
      tester,
    ) async {
      final repo = _Repo(
        history: const [
          JenkinsBuild(
            number: 42,
            url: 'https://ci.test/job/deploy/42/',
            timestamp: 1793491300000,
            causes: ['Started by user admin'],
          ),
        ],
      );
      await _pump(tester, repo: repo);
      await _confirmBoth(tester);

      expect(repo.submitted, hasLength(1));
      expect(find.text('job history'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('a refused replay stays on the editor with a reason (AC5)', (
      tester,
    ) async {
      final repo = _Repo()..submitResult = const Err(PermissionFailure());
      await _pump(tester, repo: repo);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ReplayEditScreen)),
      );
      // The toast state auto-disposes without a listener (the app's overlay).
      final toasts = container.listen(currentToastProvider, (_, _) {});
      await _confirmBoth(tester);

      expect(
        find.byKey(const ValueKey('replay-script-editor')),
        findsOneWidget,
      );
      final toast = toasts.read()!;
      expect(toast.type, ToastType.error);
      expect(toast.message, contains("can't be replayed"));
      expect(
        find.byKey(const ValueKey('replay-script-editor')),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('a read-only server turns Replay off (AC9)', (tester) async {
      await _pump(tester, readOnly: true);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Read-only'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('demo mode says it is not available (AC9)', (tester) async {
      await _pump(
        tester,
        repo: _Repo(script: const Err(DemoUnavailableFailure())),
      );
      expect(
        find.textContaining("isn't available in the demo"),
        findsOneWidget,
      );
    });

    testWidgets('the app lock re-prompt can stop the replay (AC6)', (
      tester,
    ) async {
      final lock = _DenyingLock();
      final repo = await _pump(tester, lock: lock);
      await _confirmBoth(tester);

      expect(lock.reasons, ['Confirm to replay deploy with edits']);
      expect(repo.submitted, isEmpty);
    });
  });
}
