import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'presentation/common_widgets/toast_view.dart';
import 'presentation/features/tool_selection/active_tool_notifier.dart';
import 'presentation/features/tool_selection/ci_tool.dart';
import 'presentation/navigation/app_router.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
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
      builder: (context, child) =>
          ToastOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
