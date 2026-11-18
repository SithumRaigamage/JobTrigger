import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/app_info_repository_impl.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';
import 'package:job_trigger/domain/app_info/app_info_repository.dart';
import 'package:job_trigger/presentation/features/app_info/app_info_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';

/// P14-21: app info as redesigned (`UI-UX/screens/20-app-info`).
class _Repo implements AppInfoRepository {
  _Repo(this.info);

  final AppInfo info;

  @override
  Future<Result<AppInfo, AppFailure>> fetchAppInfo() async => Ok(info);
}

Future<void> _pump(WidgetTester tester, AppInfo info) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appInfoRepositoryProvider.overrideWithValue(_Repo(info))],
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

  testWidgets('a link the backend leaves out has no row', (tester) async {
    await _pump(tester, const AppInfo(appVersion: '1.0.0', buildNumber: '7'));

    expect(find.text('Privacy policy'), findsNothing);
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
