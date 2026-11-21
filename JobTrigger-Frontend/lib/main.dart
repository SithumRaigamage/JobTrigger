import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/error/no_retry.dart';
import 'core/error_reporting/crash_reporting.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'presentation/features/app_info/update_gate.dart';
import 'presentation/common_widgets/demo_banner_gate.dart';
import 'presentation/common_widgets/toast_view.dart';
import 'data/demo/demo_mode_notifier.dart';
import 'presentation/navigation/app_router.dart';
import 'core/platform/notification_service.dart';
import 'presentation/features/app_lock/app_lock_gate.dart';
import 'presentation/features/home_widget/home_widget_sync.dart';
import 'presentation/features/home_widget/sonarqube_widget_sync.dart';
import 'presentation/features/subscription/locked_active_guard.dart';
import 'presentation/features/notifications/build_watch_notifier.dart';
import 'core/config/tool_catalog_loader.dart';
import 'presentation/features/open_link/open_link_location.dart';
import 'presentation/features/startup/startup_error_app.dart';

/// Startup normally takes tens of milliseconds. If it has not produced a
/// first frame by then, something is stuck (a plugin that never answers, a
/// hung platform channel): show a reason and a retry instead of leaving the
/// native launch screen up forever.
const _startupTimeout = Duration(seconds: 15);

Timer? _startupTimer;
var _startupGeneration = 0;
var _appShown = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _start();
}

Future<void> _start() async {
  final generation = ++_startupGeneration;
  _appShown = false;
  _startupTimer?.cancel();
  _startupTimer = Timer(_startupTimeout, () {
    if (generation != _startupGeneration || _appShown) return;
    _showStartupError(
      'The app took too long to start. Check this build’s configuration and '
      'connection, then try again.',
    );
  });

  try {
    // AUD-43: a release build without its config fails here, at launch,
    // rather than at the first backend call.
    final config = AppConfig.fromEnvironment();
    // Which tools this build supports (release/tools.json), read before the
    // first frame so nothing flickers from one answer to another.
    await loadToolCatalog();
    _registerFontLicenses();
    // E2: demo mode is read before the first frame so a relaunch stays in it.
    final demoMode = await readStoredDemoMode();
    // E3: crash reporting wraps the app (Flutter, platform and zone errors).
    // With no DSN, or with the Profile switch off, it just runs the app.
    await CrashReporting.instance.start(
      config,
      // No automatic retries: a failed load shows its error, not a spinner.
      appRunner: () {
        if (generation != _startupGeneration || _appShown) return;
        runApp(
          ProviderScope(
            retry: noRetry,
            overrides: [demoModeInitialProvider.overrideWithValue(demoMode)],
            child: const MyApp(),
          ),
        );
        // `runApp` only schedules the first frame. Keep the watchdog until
        // that frame is actually drawn: a first build that never completes
        // would otherwise leave the native launch screen up for good.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (generation != _startupGeneration) return;
          _appShown = true;
          _startupTimer?.cancel();
        });
      },
    );
  } on Object catch (error) {
    if (generation != _startupGeneration || _appShown) return;
    _showStartupError(_startupMessage(error));
  }
}

void _retryStartup() {
  _startupTimer?.cancel();
  unawaited(_start());
}

void _showStartupError(String message) {
  _appShown = true;
  _startupTimer?.cancel();
  runApp(StartupErrorApp(message: message, onRetry: _retryStartup));
}

String _startupMessage(Object error) {
  // A release build with a bad config throws a StateError whose message is
  // written for a person (AUD-43); anything else stays generic.
  if (error is StateError) return error.message;
  return 'The app could not finish starting. Please try again.';
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
      // US-SQ-WIDGET-01: and the pinned SonarQube projects' widget.
      ..watch(sonarQubeWidgetSyncProvider)
      // P20-25: a locked active credential is replaced (billing on only).
      ..watch(lockedActiveGuardProvider)
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
      scrollBehavior: AppTheme.scrollBehavior(),
      routerConfig: router,
      // US-JX-21: the lock covers everything, toasts included.
      builder: (context, child) => AppLockGate(
        child: ToastOverlay(
          // US-PROF-03: an unsupported version can't be used.
          child: UpdateRequiredGate(
            child: DemoBannerGate(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}
