import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/error/no_retry.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'presentation/common_widgets/toast_view.dart';
import 'presentation/navigation/app_router.dart';
import 'core/platform/notification_service.dart';
import 'presentation/features/app_lock/app_lock_gate.dart';
import 'presentation/features/home_widget/home_widget_sync.dart';
import 'presentation/features/notifications/build_watch_notifier.dart';
import 'presentation/features/open_link/open_link_location.dart';

void main() {
  // AUD-43: a release build without its config fails here, at launch,
  // rather than at the first backend call.
  AppConfig.fromEnvironment();
  _registerFontLicenses();
  // No automatic retries: a failed load shows its error, not a spinner.
  runApp(const ProviderScope(retry: noRetry, child: MyApp()));
}

/// P14-02: the bundled typefaces are SIL OFL 1.1, which asks for the
/// licence to travel with the fonts. Flutter's licenses page (App info →
/// Open-source licenses) lists package licences on its own; these two are
/// asset files, so they're added here.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (font, file) in const [
      ('Inter', 'Inter-OFL.txt'),
      ('JetBrains Mono', 'JetBrainsMono-OFL.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/$file'));
    }
  });
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
      // US-JX-23: keep the home-screen widget's snapshot current.
      ..watch(homeWidgetSyncProvider)
      ..listen(notificationTapsProvider, (_, next) {
        // AUD-45: through the open-link screen, which matches the job to
        // its own server and asks before switching, rather than onto
        // whichever server happens to be active.
        if (next case AsyncData(:final value)) {
          router.push(openLinkLocation(value));
        }
      });
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      title: 'JobTrigger',
      debugShowCheckedModeBanner: false,
      // P14 decision 4: one accent for the whole app, whichever CI tool is
      // active (AppTheme's doc comment).
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      // US-JX-21: the lock covers everything, toasts included.
      builder: (context, child) => AppLockGate(
        child: ToastOverlay(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
