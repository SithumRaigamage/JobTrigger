import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/platform/package_info_provider.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
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
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u', email: 'sam@acme.dev'));
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

Future<void> _pump(WidgetTester tester) async {
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
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_Auth.new),
        activeServerNotifierProvider.overrideWith(_Server.new),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'JobTrigger',
            packageName: 'app',
            version: '1.0.0',
            buildNumber: '7',
          ),
        ),
      ],
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
    // At the foot of the list, built once scrolled to.
    await tester.scrollUntilVisible(find.text('Version 1.0.0 (7)'), 200);
    expect(find.text('Version 1.0.0 (7)'), findsOneWidget);
  });

  testWidgets('holds the app lock settings, moved from Settings', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('App lock'), findsOneWidget);
  });

  testWidgets('the CI tool row is the way to switch tool', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('CI tool'));
    await tester.pumpAndSettle();

    expect(find.text('tool selection'), findsOneWidget);
  });
}
