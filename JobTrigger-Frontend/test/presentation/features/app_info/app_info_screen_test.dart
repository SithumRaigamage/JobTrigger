import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/package_info_provider.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/app_info_repository_impl.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';
import 'package:job_trigger/domain/app_info/app_info_repository.dart';
import 'package:job_trigger/presentation/features/app_info/app_info_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// P14-21: app info as redesigned (`UI-UX/screens/20-app-info`).
class _Repo implements AppInfoRepository {
  _Repo(this.info, [this.failure]);

  final AppInfo info;
  final AppFailure? failure;

  @override
  Future<Result<AppInfo, AppFailure>> fetchAppInfo() async =>
      failure == null ? Ok(info) : Err(failure!);
}

// US-PROF-03: the version shown is the installed one (package_info_plus).
final _installed = packageInfoProvider.overrideWith(
  (ref) async => PackageInfo(
    appName: 'JobTrigger',
    packageName: 'app',
    version: '1.0.0',
    buildNumber: '7',
  ),
);

Future<void> _pump(
  WidgetTester tester,
  AppInfo info, {
  AppFailure? failure,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        appInfoRepositoryProvider.overrideWithValue(_Repo(info, failure)),
        _installed,
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: const AppInfoScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the version and every link the backend provides', (
    tester,
  ) async {
    await _pump(
      tester,
      const AppInfo(
        appVersion: '1.0.0',
        buildNumber: '7',
        privacyPolicyUrl: 'https://jobtrigger.app/privacy',
        termsOfServiceUrl: 'https://jobtrigger.app/terms',
        openSourceLicensesUrl: 'https://jobtrigger.app/licenses',
        supportEmail: 'support@jobtrigger.app',
      ),
    );

    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Terms of service'), findsOneWidget);
    expect(find.text('Open-source licenses'), findsOneWidget);
    // The address is shown, not hidden behind the row.
    expect(find.text('support@jobtrigger.app'), findsOneWidget);
  });

  // US-PROF-03: the release notes link from `GET /api/appinfo`.
  testWidgets('shows Release notes when the backend links a changelog', (
    tester,
  ) async {
    await _pump(
      tester,
      const AppInfo(
        appVersion: '1.0.0',
        buildNumber: '7',
        releaseNotesUrl: 'https://jobtrigger.app/changelog',
      ),
    );

    expect(find.text('Release notes'), findsOneWidget);
  });

  // US-PROF-03 "App info fetch fails": the local version still shows; only
  // the backend's links are missing, with a retry.
  testWidgets('a failed fetch keeps the installed version on screen', (
    tester,
  ) async {
    await _pump(
      tester,
      const AppInfo(appVersion: '9.9.9', buildNumber: '1'),
      failure: const NetworkFailure(),
    );

    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('Remote access guide'), findsOneWidget);
    expect(find.text('Privacy policy'), findsNothing);
    expect(find.text('Retry Connection'), findsOneWidget);
  });

  // The backend's appVersion is a record, not what is installed.
  testWidgets('shows the installed version, not the backend\'s', (
    tester,
  ) async {
    await _pump(tester, const AppInfo(appVersion: '9.9.9', buildNumber: '1'));

    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.textContaining('9.9.9'), findsNothing);
  });

  testWidgets('a link the backend leaves out has no row', (tester) async {
    await _pump(tester, const AppInfo(appVersion: '1.0.0', buildNumber: '7'));

    expect(find.text('Privacy policy'), findsNothing);
    expect(find.text('Release notes'), findsNothing);
    expect(find.text('Contact support'), findsNothing);
  });

  // P25-05: the row used to open a mail draft; it now opens the in-app
  // Support screen, where the address is still offered as a fallback.
  testWidgets('Contact support opens the Support screen', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.appInfo,
      routes: [
        GoRoute(
          path: AppRoutes.appInfo,
          builder: (_, _) => const AppInfoScreen(),
        ),
        GoRoute(
          path: AppRoutes.support,
          builder: (_, _) => const Scaffold(body: Text('support screen')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appInfoRepositoryProvider.overrideWithValue(
            _Repo(
              const AppInfo(
                appVersion: '1.0.0',
                buildNumber: '7',
                supportEmail: 'support@jobtrigger.app',
              ),
            ),
          ),
          _installed,
        ],
        child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contact support'));
    await tester.pumpAndSettle();

    expect(find.text('support screen'), findsOneWidget);
  });
}
