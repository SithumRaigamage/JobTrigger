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
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.jobDetail,
        builder: (context, state) =>
            JobDetailScreen(job: state.extra! as JenkinsJob),
      ),
      GoRoute(
        path: AppRoutes.buildLog,
        builder: (context, state) =>
            BuildLogScreen(jenkinsBuild: state.extra! as JenkinsBuild),
      ),
      GoRoute(
        path: AppRoutes.jobHistory,
        builder: (context, state) =>
            JobHistoryScreen(job: state.extra! as JenkinsJob),
      ),
      GoRoute(
        path: AppRoutes.globalHistory,
        builder: (context, state) => const GlobalHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.appInfo,
        builder: (context, state) => const AppInfoScreen(),
      ),
    ],
  );
}
