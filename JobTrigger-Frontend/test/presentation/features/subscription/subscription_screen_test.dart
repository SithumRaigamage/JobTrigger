import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/platform/link_launcher.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/billing/revenuecat_billing_client.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/subscription/sandbox_billing.dart';
import 'package:job_trigger/domain/subscription/subscription_status.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/billing_availability.dart';
import 'package:job_trigger/presentation/features/subscription/subscription_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';

import '../../../support/fake_subscription.dart';

class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u1', email: 'a@b.dev'));
}

class _FakeSandbox implements SandboxBilling {
  final calls = <String>[];

  @override
  Future<void> cancelSubscription() async => calls.add('cancel');

  @override
  Future<void> resubscribe() async => calls.add('resubscribe');

  @override
  Future<void> expireNow() async => calls.add('expire');
}

Future<void> _pump(
  WidgetTester tester,
  SubscriptionSnapshot snapshot, {
  List<Uri>? opened,
  SandboxBilling? sandbox,
  Size size = const Size(800, 1600),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: AppRoutes.subscription,
    routes: [
      GoRoute(
        path: AppRoutes.subscription,
        builder: (_, _) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (_, _) => const Scaffold(body: Text('paywall')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(loadResult: Ok(snapshot)),
        ),
        billingClientProvider.overrideWithValue(FakeBillingClient()),
        if (sandbox != null)
          sandboxBillingProvider.overrideWithValue(sandbox),
        authNotifierProvider.overrideWith(_Auth.new),
        linkLauncherProvider.overrideWithValue((uri) async {
          opened?.add(uri);
          return true;
        }),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('subscription card fits a 320pt layout at 200% text', (
    tester,
  ) async {
    await _pump(tester, freeSnapshot, size: const Size(320, 800), textScale: 2);

    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Free: names the plan and offers Upgrade and Restore', (
    tester,
  ) async {
    await _pump(tester, freeSnapshot);

    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Renews on'), findsNothing);

    await tester.tap(find.text('Upgrade to Pro'));
    await tester.pumpAndSettle();
    expect(find.text('paywall'), findsOneWidget);
  });

  testWidgets('a store subscription shows its renewal date and links to the '
      "store's own management page", (tester) async {
    final opened = <Uri>[];
    await _pump(tester, storeProSnapshot(), opened: opened);

    expect(find.text('JobTrigger Pro'), findsOneWidget);
    expect(find.text('Renews on'), findsOneWidget);
    expect(find.text('15 Jan 2027'), findsOneWidget);
    expect(find.textContaining('Bought in the App Store'), findsOneWidget);

    await tester.tap(find.text('Manage in the App Store'));
    await tester.pumpAndSettle();
    expect(opened.single.host, 'apps.apple.com');
  });

  testWidgets('a cancelled store subscription says when it ends', (
    tester,
  ) async {
    await _pump(
      tester,
      SubscriptionSnapshot(
        entitlements: proSnapshot.entitlements,
        status: SubscriptionStatus(
          state: SubscriptionState.cancelled,
          source: SubscriptionSource.playStore,
          periodEnd: DateTime.utc(2027, 3, 2, 12),
        ),
      ),
    );

    expect(find.text('Ends on'), findsOneWidget);
    expect(find.text('Manage in the Google Play'), findsOneWidget);
    // A cancelled subscription can be bought again before it ends.
    expect(find.text('Resubscribe'), findsOneWidget);
  });

  testWidgets('a trial labels its end as the trial, not a renewal', (
    tester,
  ) async {
    await _pump(
      tester,
      SubscriptionSnapshot(
        entitlements: proSnapshot.entitlements,
        status: SubscriptionStatus(
          state: SubscriptionState.trialing,
          source: SubscriptionSource.appStore,
          periodEnd: DateTime.utc(2026, 11, 25, 12),
          willRenew: true,
        ),
      ),
    );

    expect(find.text('Trial ends'), findsOneWidget);
    expect(find.text('Renews on'), findsNothing);
  });

  testWidgets('a failed payment explains what to do and when Pro ends', (
    tester,
  ) async {
    await _pump(
      tester,
      SubscriptionSnapshot(
        entitlements: proSnapshot.entitlements,
        status: SubscriptionStatus(
          state: SubscriptionState.billingIssue,
          source: SubscriptionSource.playStore,
          periodEnd: DateTime.utc(2027, 1, 20, 12),
          willRenew: true,
        ),
      ),
    );

    expect(find.text('Pro until'), findsOneWidget);
    expect(find.textContaining("last payment didn't go through"), findsOneWidget);
    expect(find.textContaining('Google Play'), findsWidgets);
    expect(find.text('Manage in the Google Play'), findsOneWidget);
  });

  testWidgets('sandbox: the local controls cancel, expire and resubscribe '
      'without a store', (tester) async {
    final sandbox = _FakeSandbox();
    await _pump(tester, storeProSnapshot(), sandbox: sandbox);

    expect(find.text('Sandbox billing'), findsOneWidget);
    expect(
      find.textContaining('No payment is taken'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel subscription'));
    await tester.pumpAndSettle();
    expect(sandbox.calls, ['cancel']);

    await tester.tap(find.text('Simulate expiry'));
    await tester.pumpAndSettle();
    expect(sandbox.calls, ['cancel', 'expire']);
  });

  testWidgets('P20-84: a web subscription shows as Pro, with plain text and '
      'no button or link at all', (tester) async {
    final opened = <Uri>[];
    await _pump(tester, webProSnapshot, opened: opened);

    expect(find.text('JobTrigger Pro'), findsOneWidget);
    expect(
      find.textContaining('Bought on the JobTrigger website'),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.text('Upgrade to Pro'), findsNothing);
    expect(opened, isEmpty);
  });
}
