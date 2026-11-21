import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/platform/package_info_provider.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/profile/profile_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// P14-11: the profile as redesigned (`UI-UX/screens/10-profile`).
class _Auth extends AuthNotifier {
  int logouts = 0;

  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u', email: 'sam@acme.dev'));

  @override
  Future<void> logout() async => logouts++;
}

_Auth? _lastAuth;

/// US-PROF-01: no connectivity — the backend's server list can't load.
class _OfflineCredentials extends CredentialsNotifier {
  @override
  Future<List<JenkinsServer>> build() async => throw const NetworkFailure();
}

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 'a',
    serverName: 'Acme production',
    jenkinsURL: 'https://a.test',
    username: 'u',
    secret: 's',
  );
}

Future<void> _pump(WidgetTester tester, {bool offline = false}) async {
  final router = GoRouter(
    initialLocation: AppRoutes.profile,
    routes: [
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.toolSelection,
        builder: (_, _) => const Scaffold(body: Text('tool selection')),
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
        authNotifierProvider.overrideWith(() => _lastAuth = _Auth()),
        activeServerNotifierProvider.overrideWith(_Server.new),
        if (offline)
          credentialsNotifierProvider.overrideWith(_OfflineCredentials.new),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'JobTrigger',
            packageName: 'app',
            version: '1.0.0',
            buildNumber: '7',
          ),
        ),
      ],
      retry: (_, _) => null,
      child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  testWidgets('names the account and the server in use', (tester) async {
    await _pump(tester);

    expect(find.text('sam@acme.dev'), findsOneWidget);
    expect(find.textContaining('Acme production'), findsWidgets);
    // At the foot of the list, built once scrolled to. The build number is
    // deliberately not shown: the owner asked for just "Version 1.0.0".
    await tester.scrollUntilVisible(find.text('Version 1.0.0'), 200);
    expect(find.text('Version 1.0.0'), findsOneWidget);
  });

  // US-PROF-01 "No network dependency": the email, version and Log out
  // come from local state, so the screen renders offline.
  testWidgets('renders offline: email, version and Log out', (tester) async {
    await _pump(tester, offline: true);

    expect(find.text('sam@acme.dev'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Version 1.0.0'), 200);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('holds the app lock settings, moved from Settings', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('App lock'), findsOneWidget);
  });

  testWidgets('the account section opens Support', (tester) async {
    await _pump(tester);

    await tester.scrollUntilVisible(find.text('Support'), 200);
    final tile = find.widgetWithText(ListTile, 'Support');
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('support screen'), findsOneWidget);
  });

  testWidgets("the account section opens What's new", (tester) async {
    await _pump(tester);

    await tester.scrollUntilVisible(find.text("What's new"), 200);
    await tester.tap(find.text("What's new"));
    await tester.pumpAndSettle();

    expect(find.text('Version 1.0'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('the CI tool row is the way to switch tool', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('CI tool'));
    await tester.pumpAndSettle();

    expect(find.text('tool selection'), findsOneWidget);
  });

  testWidgets('Log out asks first; Cancel keeps you signed in (US-AUTH-04)', (
    tester,
  ) async {
    await _pump(tester);
    await tester.scrollUntilVisible(find.text('Log out'), 200);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(_lastAuth!.logouts, 0);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(_lastAuth!.logouts, 1);
  });
}
