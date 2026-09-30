import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'presentation/common_widgets/toast_view.dart';
import 'presentation/features/tool_selection/active_tool_notifier.dart';
import 'presentation/features/tool_selection/ci_tool.dart';
import 'presentation/navigation/app_router.dart';
import 'presentation/navigation/app_routes.dart';
import 'core/platform/notification_service.dart';
import 'domain/jenkins/jenkins_job.dart';
import 'presentation/features/app_lock/app_lock_gate.dart';
import 'presentation/features/notifications/build_watch_notifier.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // US-JX-10: resume watching at launch (and the in-app timer), and
    // open the job when a build notification is tapped.
    ref
      ..watch(buildWatchNotifierProvider)
      ..listen(notificationTapsProvider, (_, next) {
        if (next case AsyncData(:final value)) {
          final segments = Uri.tryParse(value)?.pathSegments ?? const [];
          final name = segments.where((s) => s.isNotEmpty).lastOrNull ?? 'Job';
          router.push(
            AppRoutes.jobDetail,
            extra: JenkinsJob(name: name, url: value),
          );
        }
      });
    final themeMode = ref.watch(themeNotifierProvider);
    // primary/onPrimary re-tint from the active CI/CD tool's brand color
    // once one is selected; null (pre-selection — Login/Signup/
    // ToolSelectionScreen) falls back to the original blue. See
    // ActiveToolNotifier and AppTheme's doc comment for why this isn't a
    // full ColorScheme.fromSeed reseed.
    final activeTool = ref.watch(activeToolNotifierProvider);
    final accentColor = activeTool?.accentColor ?? AppColors.brandSeed;

    return MaterialApp.router(
      title: 'JobTrigger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accentColor: accentColor),
      darkTheme: AppTheme.dark(accentColor: accentColor),
      themeMode: themeMode,
      routerConfig: router,
      // US-JX-21: the lock covers everything, toasts included.
      builder: (context, child) => AppLockGate(
        child: ToastOverlay(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
