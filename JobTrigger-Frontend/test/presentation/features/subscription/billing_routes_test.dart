import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/billing/revenuecat_billing_client.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/data/demo/demo_mode_notifier.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/subscription/entitlements.dart';
import 'package:job_trigger/domain/subscription/subscription_status.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';
import 'package:job_trigger/presentation/features/app_info/app_info_notifier.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/home/reachability_watcher.dart';
import 'package:job_trigger/presentation/features/subscription/billing_availability.dart';
import 'package:job_trigger/presentation/features/subscription/entitlements_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/paywall_screen.dart';
import 'package:job_trigger/presentation/features/subscription/subscription_screen.dart';
import 'package:job_trigger/presentation/navigation/app_router.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_subscription.dart';

class _Info extends AppInfoNotifier {
  @override
  Future<AppInfo> build() async =>
      const AppInfo(appVersion: '1', buildNumber: '1');
}

class _NoCredentials extends CredentialsNotifier {
  @override
  Future<List<JenkinsServer>> build() async => const [];
}

Future<ProviderContainer> _signedIn(
  WidgetTester tester, {
  required bool hasKey,
  required SubscriptionSnapshot snapshot,
  bool demo = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      credentialsNotifierProvider.overrideWith(_NoCredentials.new),
      appInfoNotifierProvider.overrideWith(_Info.new),
      reachabilityWatcherProvider.overrideWith((ref) {}),
      subscriptionRepositoryProvider.overrideWithValue(
        FakeSubscriptionRepository(loadResult: Ok(snapshot)),
      ),
      billingClientProvider.overrideWithValue(
        FakeBillingClient(configured: hasKey),
      ),
      demoModeInitialProvider.overrideWithValue(demo),
    ],
  );
  addTearDown(container.dispose);
  container.listen(authNotifierProvider, (_, _) {});
  container.listen(entitlementsNotifierProvider, (_, _) {});
  await container
      .read(authNotifierProvider.notifier)
      .setSession(const User(id: 'u1', email: 'a@b.com'), 'jwt-abc');
  await container.read(entitlementsNotifierProvider.future);
  final router = container.read(appRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('with no billing keys (the default build) neither screen is '
      'reachable: both go to Home', (tester) async {
    final container = await _signedIn(
      tester,
      hasKey: false,
      snapshot: freeSnapshot,
    );
    expect(container.read(billingAvailableProvider), isFalse);
    final router = container.read(appRouterProvider);

    for (final path in [AppRoutes.paywall, AppRoutes.subscription]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.home,
        reason: path,
      );
    }
    expect(find.byType(PaywallScreen), findsNothing);
    expect(find.byType(SubscriptionScreen), findsNothing);
  });

  testWidgets('keys present but BILLING_ENABLED off on the backend: still '
      'unreachable', (tester) async {
    // The backend says billingEnabled: false and everyone is Pro.
    final container = await _signedIn(
      tester,
      hasKey: true,
      snapshot: const SubscriptionSnapshot(
        entitlements: Entitlements.unrestricted,
        status: SubscriptionStatus.none,
      ),
    );
    expect(container.read(billingAvailableProvider), isFalse);
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.paywall);
    await tester.pumpAndSettle();
    expect(find.byType(PaywallScreen), findsNothing);
  });

  testWidgets('demo mode never shows subscription screens', (tester) async {
    final container = await _signedIn(
      tester,
      hasKey: true,
      snapshot: freeSnapshot,
      demo: true,
    );
    expect(container.read(billingAvailableProvider), isFalse);
  });

  testWidgets('with a key and billing on, both routes open', (tester) async {
    final container = await _signedIn(
      tester,
      hasKey: true,
      snapshot: freeSnapshot,
    );
    expect(container.read(billingAvailableProvider), isTrue);
    final router = container.read(appRouterProvider);

    router.go('${AppRoutes.paywall}?reason=multiTool');
    await tester.pumpAndSettle();
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(
      find.text('Use Jenkins, GitHub Actions and SonarQube together'),
      findsOneWidget,
    );

    router.go(AppRoutes.subscription);
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionScreen), findsOneWidget);
  });
}
