import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error_reporting/crash_reporting.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _token = ['a1b2c3d4', 'e5f60718', '2a3b4c5d', '6e7f8091'].join();

class _FakeReporting implements CrashReporting {
  bool enabledNow = true;
  final changes = <bool>[];

  @override
  bool get enabled => enabledNow;

  @override
  bool get started => false;

  @override
  Future<void> setEnabled(bool value, config) async {
    enabledNow = value;
    changes.add(value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('configureCrashReporting', () {
    late SentryFlutterOptions options;
    var on = true;

    setUp(() {
      on = true;
      options = SentryFlutterOptions();
      configureCrashReporting(
        options,
        dsn: 'https://key@glitchtip.invalid/1',
        environment: 'development',
        release: '1.0.0+7',
        isEnabled: () => on,
      );
    });

    test('names the environment and release, errors only', () {
      expect(options.environment, 'development');
      expect(options.release, '1.0.0+7');
      expect(options.tracesSampleRate, 0);
      expect(options.sendDefaultPii, isFalse);
    });

    test('collects nothing that could carry text, screens or HTTP', () {
      expect(options.maxBreadcrumbs, 0);
      expect(options.attachScreenshot, isFalse);
      // ignore: experimental_member_use
      expect(options.attachViewHierarchy, isFalse);
      expect(options.captureFailedRequests, isFalse);
      expect(options.enableUserInteractionBreadcrumbs, isFalse);
      expect(options.enableAutoNativeBreadcrumbs, isFalse);
      expect(options.enableNativeCrashHandling, isFalse);
    });

    test('caches at most 30 unsent events', () {
      expect(options.maxCacheItems, 30);
    });

    test('scrubs in beforeSend and drops events while switched off', () async {
      final event = SentryEvent(message: SentryMessage('token=$_token'));
      final sent = await options.beforeSend!(event, Hint());
      expect(sent!.toJson().toString(), isNot(contains(_token)));
      on = false;
      expect(await options.beforeSend!(event, Hint()), isNull);
    });

    test('drops every breadcrumb', () {
      expect(
        options.beforeBreadcrumb!(Breadcrumb(message: 'typed $_token'), Hint()),
        isNull,
      );
    });
  });

  group('isUnexpectedFailure (PE-25)', () {
    test('reports bugs, not expected failures', () {
      expect(isUnexpectedFailure(const UnexpectedResponseFailure()), isTrue);
      expect(isUnexpectedFailure(const UnknownFailure()), isTrue);
      for (final expected in <AppFailure>[
        const NetworkFailure(),
        const AuthFailure(),
        const PermissionFailure(),
        const NotFoundFailure(),
        const ServerFailure(503),
        const ServerFailure(500),
        const RateLimitFailure(),
      ]) {
        expect(isUnexpectedFailure(expected), isFalse, reason: '$expected');
      }
    });

    test('reporting does nothing before the SDK has started', () {
      expect(
        () => CrashReporting.instance.reportFailure(const UnknownFailure()),
        returnsNormally,
      );
    });
  });

  group('CrashReportsEnabled (PE-26)', () {
    late _FakeReporting reporting;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      reporting = _FakeReporting();
      container = ProviderContainer(
        overrides: [crashReportingProvider.overrideWithValue(reporting)],
      );
      addTearDown(container.dispose);
    });

    test('is on by default', () {
      expect(container.read(crashReportsEnabledProvider), isTrue);
    });

    test('turning it off is stored and told to the reporter', () async {
      await container
          .read(crashReportsEnabledProvider.notifier)
          .setEnabled(false);
      expect(container.read(crashReportsEnabledProvider), isFalse);
      expect(reporting.changes, [false]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(crashReportsEnabledKey), isFalse);
    });

    test('turning it back on is stored too', () async {
      final notifier = container.read(crashReportsEnabledProvider.notifier);
      await notifier.setEnabled(false);
      await notifier.setEnabled(true);
      expect(container.read(crashReportsEnabledProvider), isTrue);
      expect(reporting.changes, [false, true]);
    });
  });
}
