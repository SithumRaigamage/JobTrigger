import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/config/app_config.dart';

void main() {
  group('releaseConfigProblem (AUD-43)', () {
    test('accepts the prod config', () {
      expect(
        releaseConfigProblem(
          environmentName: 'prod',
          backendBaseUrl: 'https://api.jobtrigger.app',
        ),
        isNull,
      );
    });

    test('refuses a build with no config at all', () {
      expect(
        releaseConfigProblem(environmentName: '', backendBaseUrl: ''),
        contains('no backend configuration'),
      );
    });

    test('refuses the dev config', () {
      expect(
        releaseConfigProblem(
          environmentName: 'dev',
          backendBaseUrl: 'http://127.0.0.1:5001',
        ),
        contains('dev configuration'),
      );
    });

    test('refuses a cleartext backend', () {
      expect(
        releaseConfigProblem(
          environmentName: 'staging',
          backendBaseUrl: 'http://api-staging.jobtrigger.app',
        ),
        contains('https://'),
      );
    });
  });

  test('a release build without config throws instead of using dev', () {
    // Tests run without --dart-define, like a misconfigured store build.
    expect(
      () => AppConfig.fromEnvironment(isRelease: true),
      throwsA(isA<StateError>()),
    );
  });

  test('a debug build without config falls back to the local backend', () {
    final config = AppConfig.fromEnvironment(isRelease: false);
    expect(config.environment, AppEnvironment.dev);
    expect(config.backendBaseUrl, 'http://127.0.0.1:5001');
  });

  group('sandbox billing (development only)', () {
    test('is on only in a development build with the flag', () {
      expect(billingSandboxEnabled(isRelease: false, flag: 'true'), isTrue);
      expect(billingSandboxEnabled(isRelease: false, flag: ' true '), isTrue);
      expect(billingSandboxEnabled(isRelease: false, flag: ''), isFalse);
      expect(billingSandboxEnabled(isRelease: false, flag: '1'), isFalse);
    });

    test('can never be on in a release build', () {
      expect(billingSandboxEnabled(isRelease: true, flag: 'true'), isFalse);
    });
  });

  group('RevenueCat keys (P20-20)', () {
    test('a build with no keys has no billing on any platform', () {
      const config = AppConfig(
        environment: AppEnvironment.dev,
        backendBaseUrl: 'http://x',
      );
      expect(config.revenueCatKeyFor(TargetPlatform.iOS), isNull);
      expect(config.revenueCatKeyFor(TargetPlatform.android), isNull);
    });

    test('each platform gets its own key; others get none', () {
      const config = AppConfig(
        environment: AppEnvironment.dev,
        backendBaseUrl: 'http://x',
        revenueCatIosKey: 'appl_test',
        revenueCatAndroidKey: 'goog_test',
      );
      expect(config.revenueCatKeyFor(TargetPlatform.iOS), 'appl_test');
      expect(config.revenueCatKeyFor(TargetPlatform.android), 'goog_test');
      expect(config.revenueCatKeyFor(TargetPlatform.macOS), isNull);
    });
  });
}
