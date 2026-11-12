import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/config/app_config.dart';
import 'package:job_trigger/core/platform/link_launcher.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/presentation/features/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// US-AUTH-08: a forgotten password is reset on the website, never in the
/// app. The login screen only links out to it.
void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  Future<List<Uri>> pumpLogin(
    WidgetTester tester, {
    String? websiteBaseUrl,
  }) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig(
              environment: AppEnvironment.dev,
              backendBaseUrl: 'http://127.0.0.1:5001',
              websiteBaseUrl: websiteBaseUrl,
            ),
          ),
          linkLauncherProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return true;
          }),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const LoginScreen()),
      ),
    );
    await tester.pump();
    return opened;
  }

  final link = find.byKey(const Key('login_forgot_password'));

  testWidgets('opens the website reset page in the browser', (tester) async {
    final opened = await pumpLogin(
      tester,
      websiteBaseUrl: 'https://jobtrigger.app',
    );

    expect(find.text('Forgot password? Reset it on the web'), findsOneWidget);
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pump();

    expect(opened, [Uri.parse('https://jobtrigger.app/forgot-password')]);
  });

  testWidgets('is hidden when the build has no website', (tester) async {
    await pumpLogin(tester);
    expect(link, findsNothing);
  });

  group('websiteBaseUrlFor', () {
    test('uses the configured site without a trailing slash', () {
      expect(
        websiteBaseUrlFor(AppEnvironment.prod, 'https://jobtrigger.app/'),
        'https://jobtrigger.app',
      );
    });

    test('falls back to the local site only in dev', () {
      expect(
        websiteBaseUrlFor(AppEnvironment.dev, ''),
        'http://localhost:3000',
      );
      expect(websiteBaseUrlFor(AppEnvironment.prod, ''), isNull);
      expect(websiteBaseUrlFor(AppEnvironment.staging, '  '), isNull);
    });

    test('builds the reset page address', () {
      const config = AppConfig(
        environment: AppEnvironment.prod,
        backendBaseUrl: 'https://api.jobtrigger.app',
        websiteBaseUrl: 'https://jobtrigger.app',
      );
      expect(
        config.forgotPasswordUri,
        Uri.parse('https://jobtrigger.app/forgot-password'),
      );
    });
  });
}
