import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/link_launcher.dart';
import 'package:job_trigger/core/platform/package_info_provider.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/billing/revenuecat_billing_client.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/subscription/entitlements.dart';
import 'package:job_trigger/domain/subscription/subscription_status.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/profile/profile_screen.dart';
import 'package:job_trigger/presentation/features/subscription/entitlements_notifier.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../../support/fake_subscription.dart';

class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u', email: 'sam@acme.dev'));
}

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => null;
}

Future<void> _pump(
  WidgetTester tester, {
  required bool hasKey,
  required SubscriptionSnapshot snapshot,
  List<Uri>? opened,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: AppRoutes.profile,
    routes: [
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (_, _) => const Scaffold(body: Text('subscription screen')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_Auth.new),
        activeServerNotifierProvider.overrideWith(_Server.new),
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(loadResult: Ok(snapshot)),
        ),
        billingClientProvider.overrideWithValue(
          FakeBillingClient(configured: hasKey),
        ),
        linkLauncherProvider.overrideWithValue((uri) async {
          opened?.add(uri);
          return true;
        }),
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
  // Let the entitlements load, as they do once a screen reads them.
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ProfileScreen)),
  );
  container.listen(entitlementsNotifierProvider, (_, _) {});
  await container.read(entitlementsNotifierProvider.future);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  testWidgets('a default build (no keys) has no Subscription row', (
    tester,
  ) async {
    await _pump(tester, hasKey: false, snapshot: freeSnapshot);
    expect(find.text('Subscription'), findsNothing);
    expect(find.text('Change password'), findsOneWidget);
  });

  testWidgets('with billing available the row shows the plan and opens the '
      'Subscription screen', (tester) async {
    await _pump(tester, hasKey: true, snapshot: freeSnapshot);

    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);

    await tester.tap(find.text('Subscription'));
    await tester.pumpAndSettle();
    expect(find.text('subscription screen'), findsOneWidget);
  });

  testWidgets('deleting an account with a renewing store subscription '
      'warns, and links to the store', (tester) async {
    final opened = <Uri>[];
    await _pump(
      tester,
      hasKey: true,
      snapshot: storeProSnapshot(),
      opened: opened,
    );

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Delete account?'), findsOneWidget);
    expect(
      find.textContaining('cannot be deleted while it is renewing'),
      findsOneWidget,
    );
    await tester.tap(find.text('Manage subscription'));
    await tester.pumpAndSettle();
    expect(opened.single.host, anyOf('apps.apple.com', 'play.google.com'));
  });

  testWidgets('no warning for Free, or for a web subscription', (tester) async {
    for (final snapshot in [freeSnapshot, webProSnapshot]) {
      await _pump(tester, hasKey: true, snapshot: snapshot);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();

      expect(find.text('Delete account?'), findsOneWidget);
      expect(find.textContaining('keeps renewing'), findsNothing);
      expect(find.text('Manage subscription'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('the delete dialog is unchanged when the backend has billing '
      'off', (tester) async {
    await _pump(
      tester,
      hasKey: false,
      snapshot: SubscriptionSnapshot(
        entitlements: Entitlements.unrestricted,
        status: storeProSnapshot().status,
      ),
    );
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Your account and every Jenkins server'),
      findsOneWidget,
    );
    expect(find.textContaining('keeps renewing'), findsNothing);
  });
}
