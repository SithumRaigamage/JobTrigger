import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/config/app_config.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/link_launcher.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/billing/revenuecat_billing_client.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/presentation/common_widgets/inline_alert.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/app_info/app_info_notifier.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/paywall_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';

import '../../../support/fake_subscription.dart';

class _InfoWithoutUrls extends AppInfoNotifier {
  @override
  Future<AppInfo> build() async =>
      const AppInfo(appVersion: '1.0.0', buildNumber: '1');
}

class _InfoFails extends AppInfoNotifier {
  @override
  Future<AppInfo> build() async => throw const NetworkFailure();
}

class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u1', email: 'a@b.dev'));
}

class _Info extends AppInfoNotifier {
  @override
  Future<AppInfo> build() async => const AppInfo(
    appVersion: '1.0.0',
    buildNumber: '1',
    privacyPolicyUrl: 'https://site.test/privacy',
    termsOfServiceUrl: 'https://site.test/terms',
  );
}

/// Pumps the paywall over a "home" route, so closing it is observable.
Future<ProviderContainer> pumpPaywall(
  WidgetTester tester,
  FakeSubscriptionRepository repo, {
  String? reason,
  List<Uri>? opened,
  AppInfoNotifier Function()? info,
  String? websiteBaseUrl,
}) async {
  // Tall enough to build the whole list (it is lazy).
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: AppRoutes.paywall,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (_, _) => PaywallScreen(reason: reason),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(repo),
        billingClientProvider.overrideWithValue(FakeBillingClient()),
        authNotifierProvider.overrideWith(_Auth.new),
        appInfoNotifierProvider.overrideWith(info ?? _Info.new),
        if (websiteBaseUrl != null)
          appConfigProvider.overrideWithValue(
            AppConfig(
              environment: AppEnvironment.prod,
              backendBaseUrl: 'https://api.test',
              websiteBaseUrl: websiteBaseUrl,
            ),
          ),
        linkLauncherProvider.overrideWithValue((uri) async {
          opened?.add(uri);
          return true;
        }),
      ],
      child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(PaywallScreen)),
  );
  // The toast provider is auto-dispose; hold it so a toast can be read.
  container.listen(currentToastProvider, (_, _) {});
  return container;
}

void main() {
  testWidgets('shows the store prices, the trial and what it converts to, '
      'auto-renew text, Restore and the legal links', (tester) async {
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot));
    await pumpPaywall(tester, repo);

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('LKR 1,200.00 / month'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
    expect(
      find.text('7-day free trial, then LKR 9,900.00 / year'),
      findsOneWidget,
    );
    // The trial offer is preselected, so the button names it.
    expect(find.text('Start 7-day free trial'), findsOneWidget);
    expect(
      find.textContaining('Auto-renews until cancelled. Cancel any time in '),
      findsOneWidget,
    );
    expect(find.text('Restore purchases'), findsOneWidget);
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  testWidgets('the headline follows the reason', (tester) async {
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot));
    await pumpPaywall(tester, repo, reason: 'maxCredentialsTotal');
    expect(find.text('Add more servers with Pro'), findsOneWidget);
  });

  testWidgets('choosing monthly changes the button and what is bought', (
    tester,
  ) async {
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot))
      ..refreshResult = Ok(storeProSnapshot());
    await pumpPaywall(tester, repo);

    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(find.text('Subscribe'), findsOneWidget);

    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();

    expect(repo.purchased, ['monthly']);
  });

  testWidgets('a purchase confirms and closes the paywall', (tester) async {
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot))
      ..refreshResult = Ok(storeProSnapshot());
    final container = await pumpPaywall(tester, repo);

    await tester.tap(find.text('Start 7-day free trial'));
    await tester.pumpAndSettle();

    expect(container.read(currentToastProvider)?.title, 'Welcome to Pro');
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('home'), findsOneWidget);
    expect(repo.purchased, ['yearly']);
  });

  testWidgets('closing the store sheet shows nothing: no toast, no error, '
      'paywall stays', (tester) async {
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot))
      ..purchaseResult = const Err(PurchaseCancelled());
    final container = await pumpPaywall(tester, repo);

    await tester.tap(find.text('Start 7-day free trial'));
    await tester.pumpAndSettle();

    expect(container.read(currentToastProvider), isNull);
    expect(find.byType(InlineAlert), findsNothing);
    expect(find.text('Start 7-day free trial'), findsOneWidget);
    expect(find.text('home'), findsNothing);
  });

  testWidgets('a failed purchase says so', (tester) async {
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot))
      ..purchaseResult = const Err(UnknownFailure('declined'));
    final container = await pumpPaywall(tester, repo);

    await tester.tap(find.text('Start 7-day free trial'));
    await tester.pumpAndSettle();

    final toast = container.read(currentToastProvider);
    expect(toast?.type, ToastType.error);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('home'), findsNothing);
  });

  testWidgets('restore with nothing to restore says so', (tester) async {
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot))
      ..refreshResult = const Ok(freeSnapshot);
    final container = await pumpPaywall(tester, repo);

    await tester.tap(find.text('Restore purchases'));
    await tester.pumpAndSettle();

    expect(container.read(currentToastProvider)?.title, 'Nothing to restore');
    await tester.pump(const Duration(seconds: 4));
    expect(repo.restores, 1);
  });

  testWidgets('Terms and Privacy open the backend-provided links', (
    tester,
  ) async {
    final opened = <Uri>[];
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot));
    await pumpPaywall(tester, repo, opened: opened);

    await tester.tap(find.text('Terms of Use'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    expect(opened.map((u) => u.toString()), [
      'https://site.test/terms',
      'https://site.test/privacy',
    ]);
  });

  for (final entry in {
    '/api/appinfo has no URLs': _InfoWithoutUrls.new,
    '/api/appinfo fails': _InfoFails.new,
  }.entries) {
    testWidgets('${entry.key}: Terms and Privacy fall back to the website', (
      tester,
    ) async {
      final repo = FakeSubscriptionRepository(
        loadResult: const Ok(freeSnapshot),
      );
      final opened = <Uri>[];
      await pumpPaywall(
        tester,
        repo,
        opened: opened,
        info: entry.value,
        websiteBaseUrl: 'https://site.test',
      );

      await tester.tap(find.text('Terms of Use'));
      await tester.pump();
      await tester.tap(find.text('Privacy Policy'));
      await tester.pump();
      expect(opened.map((u) => u.toString()), [
        'https://site.test/terms',
        'https://site.test/privacy',
      ]);
    });
  }

  testWidgets('P20-84: a web subscription is Pro: nothing to buy, no restore, '
      'and no link to anywhere', (tester) async {
    final opened = <Uri>[];
    final repo = FakeSubscriptionRepository(loadResult: Ok(webProSnapshot));
    await pumpPaywall(tester, repo, opened: opened);

    expect(find.textContaining('You already have Pro'), findsOneWidget);
    expect(
      find.textContaining('bought on the JobTrigger website'),
      findsOneWidget,
    );
    expect(find.text('Monthly'), findsNothing);
    expect(find.textContaining('Start'), findsNothing);
    expect(find.text('Subscribe'), findsNothing);
    expect(find.text('Restore purchases'), findsNothing);
    // Only the legal links remain; none points at web checkout.
    expect(opened, isEmpty);
  });

  testWidgets('offers that fail to load can be retried', (tester) async {
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot))
      ..offerResult = const Err(NetworkFailure());
    await pumpPaywall(tester, repo);

    expect(find.textContaining("Can't reach the server"), findsOneWidget);

    repo.offerResult = const Ok([]);
    await tester.tap(find.text('Retry Connection'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Subscriptions are not available right now'),
      findsOneWidget,
    );
  });
}
