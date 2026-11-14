import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../error/app_failure.dart';
import 'event_scrubber.dart';

part 'crash_reporting.g.dart';

/// `shared_preferences` key for the "Send crash reports" switch (PE-26).
/// Not a secret, so not secure storage (`CLAUDE.md` §7).
const crashReportsEnabledKey = 'crash_reports_enabled';

/// Whether [failure] is a bug worth reporting (PE-25): the response couldn't
/// be understood, or nothing could say what went wrong. Expected failures
/// (offline, wrong credentials, a stopped server, 5xx from the user's own
/// Jenkins) are not.
bool isUnexpectedFailure(AppFailure failure) =>
    failure is UnexpectedResponseFailure || failure is UnknownFailure;

/// Applies the app's reporting rules to [options] (PE-24).
///
/// Exposed so a test can check them. Every switch here removes a source of
/// data rather than relying on the scrubber alone:
/// no breadcrumbs, screenshots, view hierarchy, tracing, sessions or HTTP
/// capture, and native crash/hang handlers off, because a native report
/// would reach disk without passing [scrubEvent] ("never write an unscrubbed
/// event anywhere", `docs/error-reporting.md`).
@visibleForTesting
void configureCrashReporting(
  SentryFlutterOptions options, {
  required String dsn,
  required String environment,
  required String release,
  required bool Function() isEnabled,
}) {
  options
    ..dsn = dsn
    ..environment = environment
    ..release = release
    ..sendDefaultPii = false
    ..tracesSampleRate = 0
    ..maxBreadcrumbs = 0
    ..maxCacheItems = 30
    ..attachScreenshot = false
    // Marked experimental in sentry_flutter 9.x (stable in 10.x); it is the
    // switch that keeps screen contents out of reports, so it stays set.
    // ignore: experimental_member_use
    ..attachViewHierarchy = false
    ..attachStacktrace = true
    ..captureFailedRequests = false
    ..enableAutoPerformanceTracing = false
    ..enableUserInteractionTracing = false
    ..enableUserInteractionBreadcrumbs = false
    ..enableAutoNativeBreadcrumbs = false
    ..enableAutoSessionTracking = false
    ..enableNativeCrashHandling = false
    ..enableAppHangTracking = false
    ..enableWatchdogTerminationTracking = false
    ..anrEnabled = false
    ..enableFramesTracking = false
    ..sendClientReports = false
    ..beforeBreadcrumb = (breadcrumb, hint) => null;
  options.beforeSend = (event, hint) => isEnabled() ? scrubEvent(event) : null;
}

/// Crash and error reporting (E3): `sentry_flutter` pointed at GlitchTip.
///
/// Off without a DSN (`SENTRY_DSN` in the build config) and when the user
/// turned "Send crash reports" off. Unsent events wait in the SDK's own
/// on-disk cache (at most 30) and are retried on the next launch; they are
/// scrubbed *before* they reach it.
class CrashReporting {
  CrashReporting._();

  static final CrashReporting instance = CrashReporting._();

  bool _enabled = true;
  bool _started = false;

  /// Whether reports may be sent right now (the switch in Profile).
  bool get enabled => _enabled;

  /// True once the SDK has been started.
  bool get started => _started;

  /// Starts the SDK (when a DSN is set and reporting is on) and then runs
  /// [appRunner] inside its error zone; otherwise just runs it.
  Future<void> start(
    AppConfig config, {
    required FutureOr<void> Function() appRunner,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(crashReportsEnabledKey) ?? true;
    final dsn = config.crashReportDsn;
    if (dsn == null || !_enabled) {
      await appRunner();
      return;
    }
    final release = await _release();
    _started = true;
    await SentryFlutter.init(
      (options) => configureCrashReporting(
        options,
        dsn: dsn,
        environment: _environmentName(config.environment),
        release: release,
        isEnabled: () => _enabled,
      ),
      appRunner: appRunner,
    );
  }

  /// The "Send crash reports" switch (PE-26). Turning it off stops sending
  /// at once and clears what is waiting in the offline cache; turning it on
  /// starts the SDK if this launch didn't.
  Future<void> setEnabled(bool value, AppConfig config) async {
    _enabled = value;
    if (!value) {
      await clearOfflineCache();
      return;
    }
    final dsn = config.crashReportDsn;
    if (dsn != null && !_started) {
      final release = await _release();
      _started = true;
      await SentryFlutter.init(
        (options) => configureCrashReporting(
          options,
          dsn: dsn,
          environment: _environmentName(config.environment),
          release: release,
          isEnabled: () => _enabled,
        ),
      );
    }
  }

  /// Deletes the SDK's unsent events. Best effort: the folders are the
  /// native SDKs' cache locations (`io.sentry` on iOS, `sentry` on Android),
  /// under the app's own cache directory.
  Future<void> clearOfflineCache() async {
    try {
      final cache = await getApplicationCacheDirectory();
      for (final name in const ['io.sentry', 'sentry']) {
        final dir = Directory('${cache.path}/$name');
        if (dir.existsSync()) await dir.delete(recursive: true);
      }
    } on Object {
      // Nothing to clear, or no cache folder on this platform.
    }
  }

  /// Reports a failure the app didn't expect (PE-25), from the repository
  /// layer. Does nothing when reporting is off or [failure] is expected.
  void reportFailure(
    AppFailure failure, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_started || !_enabled || !isUnexpectedFailure(failure)) return;
    // Only the failure's name and the error's type: an error's own text can
    // quote part of a response body (a FormatException shows its source),
    // and a report carries no bodies. The stack trace says where.
    final cause = error == null ? '' : ' (${error.runtimeType})';
    unawaited(
      Sentry.captureException(
        StateError('${failure.runtimeType}$cause'),
        stackTrace: stackTrace,
        withScope: (scope) =>
            scope.setTag('app_failure', '${failure.runtimeType}'),
      ),
    );
  }

  /// A deliberate report, to see the whole path work (Profile, debug and
  /// profile builds only). The message carries made-up credentials so the
  /// dashboard shows they were scrubbed.
  Future<void> sendTestReport() async {
    // Assembled at runtime so no token-shaped literal sits in the source
    // tree (the repository guard, AUD-66). Made up; authenticates nothing.
    final fakeToken = ['a1b2c3d4', 'e5f60718', '2a3b4c5d', '6e7f8091'].join();
    await Sentry.captureException(
      StateError(
        'Test crash report. token=$fakeToken '
        'url=https://user:pass@jenkins.example.com/job/x?token=$fakeToken',
      ),
      stackTrace: StackTrace.current,
    );
  }

  /// `<version>+<build>` (PE-24).
  static Future<String> _release() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  static String _environmentName(AppEnvironment environment) =>
      switch (environment) {
        AppEnvironment.dev => 'development',
        AppEnvironment.staging => 'staging',
        AppEnvironment.prod => 'production',
      };
}

@Riverpod(keepAlive: true)
CrashReporting crashReporting(Ref ref) => CrashReporting.instance;

/// The "Send crash reports" switch (PE-26): on by default, stored in
/// `shared_preferences`.
@riverpod
class CrashReportsEnabled extends _$CrashReportsEnabled {
  @override
  bool build() => ref.read(crashReportingProvider).enabled;

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(crashReportsEnabledKey, value);
    await ref
        .read(crashReportingProvider)
        .setEnabled(value, ref.read(appConfigProvider));
  }
}
