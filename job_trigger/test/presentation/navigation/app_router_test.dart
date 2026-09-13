import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/jenkins_repository.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/home/folder_breadcrumb_notifier.dart';
import 'package:job_trigger/presentation/features/home/home_screen.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';
import 'package:job_trigger/presentation/navigation/app_router.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:job_trigger/presentation/navigation/main_scaffold.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _fakeServer = JenkinsServer(
  id: 's1',
  serverName: 'Test Server',
  jenkinsURL: 'https://jenkins.test',
  username: 'user',
  secret: 'secret',
);

/// Reused fake from `home_screen_test.dart`'s pattern -- private to each
/// file since it's not exported there.
class _FakeJenkinsRepository implements JenkinsRepository {
  _FakeJenkinsRepository(this._jobs);

  final List<JenkinsJob> _jobs;

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() async =>
      Ok(_jobs);

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) =>
      throw UnimplementedError();

  @override
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  }) => throw UnimplementedError();

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl,
  ) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    String? paramToken,
  }) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl) =>
      throw UnimplementedError();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  testWidgets(
    'HomeScreen breadcrumb back-navigation still works nested inside the '
    'real StatefulShellRoute (P6-14)',
    (tester) async {
      const folder = JenkinsJob(
        name: 'Projects',
        url: 'https://jenkins.test/job/Projects/',
        jobs: [],
      );
      final repo = _FakeJenkinsRepository([folder]);
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      // Keep authNotifierProvider alive across the gap between setSession
      // and the widget tree observing it -- same pitfall as
      // session_expiry_test.dart / home_screen_test.dart.
      container.listen(authNotifierProvider, (_, _) {});

      await container
          .read(authNotifierProvider.notifier)
          .setSession(const User(id: 'u1', email: 'a@b.com'), 'jwt-abc');

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Authenticated -> redirected off /login to /tools. Jump straight
      // into the shell the same way tapping the Jenkins tool card would
      // (tool_selection_screen.dart's own flow is covered elsewhere; this
      // test is specifically about the shell + breadcrumb interaction).
      router.go(AppRoutes.home);
      await tester.pumpAndSettle();

      // HomeScreen shows a "no server" empty state until one is active.
      await container
          .read(activeServerNotifierProvider.notifier)
          .setActiveServer(_fakeServer);
      await tester.pumpAndSettle();

      expect(find.byType(MainScaffold), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );

      container
          .read(folderBreadcrumbNotifierProvider.notifier)
          .navigateInto(folder);
      await tester.pumpAndSettle();
      expect(container.read(folderBreadcrumbNotifierProvider), hasLength(1));

      // The Navigator that actually owns HomeScreen is the Home branch's
      // own nested Navigator, not the shell's root one -- find it via its
      // relationship to HomeScreen rather than assuming tree order.
      final homeNavigator = tester.state<NavigatorState>(
        find
            .ancestor(
              of: find.byType(HomeScreen),
              matching: find.byType(Navigator),
            )
            .first,
      );
      final popped = await homeNavigator.maybePop();
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(container.read(folderBreadcrumbNotifierProvider), isEmpty);
      // HomeScreen's own inner PopScope intercepted the pop -- the shell
      // and tab bar are untouched, still on the Home tab.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
    },
  );
}
