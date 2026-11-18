import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:job_trigger/core/error/result.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/network/backend_api_client.dart';
import 'package:job_trigger/core/platform/home_widget_bridge.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/cache/job_tree_cache.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/home/reachability_watcher.dart';
import 'package:job_trigger/data/credentials/active_github_credential_notifier.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/datasources/github_client_factory.dart';
import 'package:job_trigger/data/datasources/jenkins_client_factory.dart';
import 'package:job_trigger/data/datasources/sonarqube_client_factory.dart';
import 'package:job_trigger/data/demo/demo_github_repository.dart';
import 'package:job_trigger/data/demo/demo_jenkins_repository.dart';
import 'package:job_trigger/data/demo/demo_mode_notifier.dart';
import 'package:job_trigger/data/demo/demo_sonarqube_repository.dart';
import 'package:job_trigger/data/repositories/auth_repository_impl.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/presentation/common_widgets/demo_banner_gate.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/auth/login_screen.dart';
import 'package:job_trigger/presentation/features/home_widget/home_widget_sync.dart';
import 'package:job_trigger/presentation/features/notifications/build_watch_notifier.dart';
import 'package:job_trigger/presentation/features/tool_selection/active_tool_notifier.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';
import 'package:job_trigger/presentation/navigation/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_home_widget_bridge.dart';

/// E2 (PE-11, PE-12, PE-14, PE-15): demo mode as a whole.

/// Any attempt to build a network client throws, which proves none is used.
Dio _noNetwork(Ref ref) => throw StateError('A Dio client was built in demo.');

/// A cache that stores nothing, so no test waits on `path_provider`.
class _NoCache extends JobTreeCache {
  _NoCache() : super(() => throw UnimplementedError());

  @override
  Future<CachedListing?> read(String serverId, String folderKey) async => null;

  @override
  Future<void> write(
    String serverId,
    String folderKey,
    List<JenkinsJob> jobs, {
    DateTime? now,
  }) async {}

  @override
  Future<void> clearServer(String serverId) async {}

  @override
  Future<void> clearAll() async {}
}

List<Override> _noClients() => [
  jobTreeCacheProvider.overrideWithValue(_NoCache()),
  reachabilityWatcherProvider.overrideWith((ref) {}),
  dioBackendProvider.overrideWith(_noNetwork),
  jenkinsClientProvider.overrideWith(_noNetwork),
  gitHubClientProvider.overrideWith(_noNetwork),
  sonarQubeClientProvider.overrideWith(_noNetwork),
];

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('DemoModeNotifier', () {
    test('is off by default and stores nothing secret', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(demoModeNotifierProvider), isFalse);

      await container.read(demoModeNotifierProvider.notifier).enter();
      expect(container.read(demoModeNotifierProvider), isTrue);
      expect(await readStoredDemoMode(), isTrue);

      await container.read(demoModeNotifierProvider.notifier).exit();
      expect(container.read(demoModeNotifierProvider), isFalse);
      expect(await readStoredDemoMode(), isFalse);
    });

    test('starts on when the stored flag was on', () async {
      SharedPreferences.setMockInitialValues({demoModePrefKey: true});
      final container = ProviderContainer(
        overrides: [
          demoModeInitialProvider.overrideWithValue(await readStoredDemoMode()),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(demoModeNotifierProvider), isTrue);
    });
  });

  group('repositories', () {
    test('are the real ones when demo is off', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(demoModeNotifierProvider), isFalse);
      expect(container.read(authRepositoryProvider), isA<AuthRepositoryImpl>());
    });

    test('are the demo ones when demo is on, and build no client', () async {
      final container = ProviderContainer(
        overrides: [
          demoModeInitialProvider.overrideWithValue(true),
          ..._noClients(),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(jenkinsRepositoryProvider),
        isA<DemoJenkinsRepository>(),
      );
      expect(
        container.read(gitHubRepositoryProvider),
        isA<DemoGitHubRepository>(),
      );
      expect(
        container.read(sonarQubeRepositoryProvider),
        isA<DemoSonarQubeRepository>(),
      );
      // Reading the account side must not touch the backend client either.
      container.read(authRepositoryProvider);
    });
  });

  group('AuthNotifier', () {
    test(
      'enterDemo signs in as the sample user, with no session stored',
      () async {
        final container = ProviderContainer(overrides: _noClients());
        addTearDown(container.dispose);
        container.listen(authNotifierProvider, (_, _) {});
        await container.read(authNotifierProvider.future);

        await container.read(authNotifierProvider.notifier).enterDemo();

        final auth = container.read(authNotifierProvider).value;
        expect(auth, isA<Authenticated>());
        expect(
          const FlutterSecureStorage().read(key: 'jwt_token'),
          completion(isNull),
        );
      },
    );

    test(
      'a relaunch in demo mode is still in demo and reads no storage',
      () async {
        SharedPreferences.setMockInitialValues({demoModePrefKey: true});
        final container = ProviderContainer(
          overrides: [
            demoModeInitialProvider.overrideWithValue(true),
            ..._noClients(),
          ],
        );
        addTearDown(container.dispose);
        expect(
          (await container.read(authNotifierProvider.future)),
          isA<Authenticated>(),
        );
      },
    );

    test('exitDemo clears demo state and returns to signed out', () async {
      final container = ProviderContainer(overrides: _noClients());
      addTearDown(container.dispose);
      container.listen(authNotifierProvider, (_, _) {});
      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).enterDemo();
      SharedPreferences.setMockInitialValues({
        demoModePrefKey: true,
        'active_server_id': 'demo-jenkins',
        'pinned_jobs_x': ['a'],
      });

      await container.read(authNotifierProvider.notifier).exitDemo();

      expect(
        container.read(authNotifierProvider).value,
        isA<Unauthenticated>(),
      );
      expect(container.read(demoModeNotifierProvider), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('log out inside the demo is the same as exiting it', () async {
      final container = ProviderContainer(overrides: _noClients());
      addTearDown(container.dispose);
      container.listen(authNotifierProvider, (_, _) {});
      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).enterDemo();

      await container.read(authNotifierProvider.notifier).logout();

      expect(container.read(demoModeNotifierProvider), isFalse);
      expect(
        container.read(authNotifierProvider).value,
        isA<Unauthenticated>(),
      );
    });
  });

  group('never touches real data (PE-14)', () {
    test('no build watch can be added', () async {
      final container = ProviderContainer(
        overrides: [demoModeInitialProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);
      final repo = DemoJenkinsRepository();
      final job = (await repo.fetchJobDetail(
        'https://jenkins.demo.invalid/job/docs-site/',
      )).fold((j) => j, (e) => fail('$e'));
      final result = await container
          .read(buildWatchNotifierProvider.notifier)
          .watchJob(job);
      expect(result, WatchResult.unavailableInDemo);
      expect(container.read(buildWatchNotifierProvider), isEmpty);
    });

    test('the home-screen widget snapshot is never written', () async {
      final bridge = FakeHomeWidgetBridge();
      final container = ProviderContainer(
        overrides: [
          demoModeInitialProvider.overrideWithValue(true),
          ..._noClients(),
          homeWidgetBridgeProvider.overrideWithValue(bridge),
        ],
      );
      addTearDown(container.dispose);
      container.listen(authNotifierProvider, (_, _) {});
      await container.read(authNotifierProvider.future);
      container.listen(homeWidgetSyncProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bridge.written, isEmpty);
    });
  });

  group('screens in demo mode', () {
    Future<ProviderContainer> pumpApp(WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          demoModeInitialProvider.overrideWithValue(true),
          ..._noClients(),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) => MaterialApp.router(
              theme: AppTheme.light(),
              routerConfig: ref.watch(appRouterProvider),
              builder: (context, child) =>
                  DemoBannerGate(child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    /// Unmounts the app and disposes the container before the test ends, so
    /// no poller's timer outlives it.
    Future<void> finish(WidgetTester tester, ProviderContainer c) async {
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }

    Future<void> chooseTool(WidgetTester tester, CiTool tool) async {
      await tester.tap(find.byKey(Key('tool_card_${tool.name}')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('tool_continue_button')));
      await tester.pumpAndSettle();
    }

    testWidgets('lands on tool selection with the Demo banner', (tester) async {
      final c = await pumpApp(tester);
      expect(find.byKey(const Key('demo_banner')), findsOneWidget);
      expect(find.text('Exit demo'), findsOneWidget);
      expect(find.byKey(const Key('tool_continue_button')), findsOneWidget);
      expect(
        find.text(
          'Jenkins for builds · GitHub Actions for workflows · '
          'SonarQube for code quality.',
        ),
        findsOneWidget,
      );
      await finish(tester, c);
    });

    testWidgets('Jenkins Home lists the sample jobs', (tester) async {
      final c = await pumpApp(tester);
      await chooseTool(tester, CiTool.jenkins);
      expect(find.text('demo-app'), findsWidgets);
      expect(find.text('docs-site'), findsWidgets);
      await finish(tester, c);
    });

    testWidgets('GitHub Actions lists the sample repositories', (tester) async {
      final c = await pumpApp(tester);
      await chooseTool(tester, CiTool.githubActions);
      expect(find.textContaining('app'), findsWidgets);
      await finish(tester, c);
    });

    testWidgets('SonarQube lists the sample projects', (tester) async {
      final c = await pumpApp(tester);
      await chooseTool(tester, CiTool.sonarqube);
      expect(find.text('Demo App'), findsWidgets);
      expect(find.text('Demo API'), findsWidgets);
      await finish(tester, c);
    });

    testWidgets('Exit demo returns to sign-in and clears the banner', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('demo_exit_button')));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byKey(const Key('demo_banner')), findsNothing);
      expect(container.read(demoModeNotifierProvider), isFalse);
      expect(container.read(activeServerNotifierProvider), isNull);
      expect(container.read(activeGitHubCredentialNotifierProvider), isNull);
      expect(container.read(activeToolNotifierProvider), isNull);
      await finish(tester, container);
    });
  });

  group('sign-in screen', () {
    testWidgets('"Try the demo" signs in without a backend call', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(overrides: _noClients());
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: AppTheme.dark(), home: const LoginScreen()),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('login_demo_button')), findsOneWidget);

      // The startup session check uses platform channels: let it finish.
      container.listen(authNotifierProvider, (_, _) {});
      await tester.runAsync(() => container.read(authNotifierProvider.future));

      await tester.tap(find.byKey(const Key('login_demo_button')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      expect(container.read(demoModeNotifierProvider), isTrue);
      expect(container.read(authNotifierProvider).value, isA<Authenticated>());
    });
  });
}
