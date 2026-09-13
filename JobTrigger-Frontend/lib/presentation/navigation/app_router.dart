import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/auth/auth_state.dart';
import '../../domain/jenkins/jenkins_build.dart';
import '../../domain/jenkins/jenkins_job.dart';
import '../features/app_info/app_info_screen.dart';
import '../features/auth/auth_notifier.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/build_log/build_log_screen.dart';
import '../features/history/global_history_screen.dart';
import '../features/history/job_history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/job_detail/job_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tool_selection/tool_selection_screen.dart';
import 'app_routes.dart';
import 'main_scaffold.dart';

part 'app_router.g.dart';

/// Notifies `go_router` to re-run `redirect` whenever `authNotifierProvider`
/// changes, without recreating the `GoRouter` instance itself (which would
/// blow away navigation history). Standard riverpod+go_router integration
/// pattern — see the `refreshListenable` wiring below.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authNotifierProvider, (previous, next) => notifyListeners());
  }
}

const _authRoutes = {AppRoutes.login, AppRoutes.signup};

/// Module-level (not inside `appRouter`) so identity is stable across
/// provider rebuilds — required by `GlobalKey<NavigatorState>`. Used by
/// drill-down detail routes (job detail, build log, job history, app info)
/// so they always land on the app's root navigator — full-screen over
/// [MainScaffold]'s tab bar — regardless of which tab pushed them (P6-14;
/// see `docs/architecture.md`'s `main_scaffold.dart` mapping row and
/// `tasks/backlog.md`'s now-promoted bottom-tab-bar item).
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refreshListenable = _AuthRefreshListenable(ref);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authAsync = ref.read(authNotifierProvider);
      // Still rehydrating from secure storage (P2-04) — don't redirect yet;
      // `refreshListenable` fires again once this resolves.
      if (authAsync.isLoading) return null;

      final isAuthenticated = authAsync.value is Authenticated;
      final onAuthRoute = _authRoutes.contains(state.matchedLocation);

      if (isAuthenticated && onAuthRoute) return AppRoutes.toolSelection;
      if (!isAuthenticated && !onAuthRoute) return AppRoutes.login;
      return null;
    },
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.toolSelection,
        builder: (context, state) => const ToolSelectionScreen(),
      ),
      // Drill-down detail routes: pinned to the root navigator so they
      // always render full-screen over MainScaffold's tab bar, regardless
      // of which branch/tab pushed them (P6-14). Without this, a route
      // nested inside one branch's own subtree would force go_router to
      // re-resolve into that branch on push, silently flipping the active
      // tab — e.g. pushing buildLog from the History tab would jump the
      // tab bar to Home if buildLog lived under Home's branch.
      GoRoute(
        path: AppRoutes.jobDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            JobDetailScreen(job: state.extra! as JenkinsJob),
      ),
      GoRoute(
        path: AppRoutes.buildLog,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            BuildLogScreen(jenkinsBuild: state.extra! as JenkinsBuild),
      ),
      GoRoute(
        path: AppRoutes.jobHistory,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            JobHistoryScreen(job: state.extra! as JenkinsJob),
      ),
      GoRoute(
        path: AppRoutes.appInfo,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AppInfoScreen(),
      ),
      // Persistent bottom tab bar (P6-14) — Home/History/Settings/Profile.
      // See main_scaffold.dart.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.globalHistory,
                builder: (context, state) => const GlobalHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
