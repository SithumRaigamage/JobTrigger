import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/billing/revenuecat_billing_client.dart';
import 'package:job_trigger/data/demo/demo_mode_notifier.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/subscription/subscription_status.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/promo_redeem_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/subscription_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';

import '../../../support/fake_subscription.dart';

class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u1', email: 'a@b.dev'));
}

Future<void> _pump(
  WidgetTester tester,
  FakeSubscriptionRepository repo,
  SubscriptionSnapshot snapshot,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  repo.loadResult = Ok(snapshot);
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
        subscriptionRepositoryProvider.overrideWithValue(repo),
        billingClientProvider.overrideWithValue(FakeBillingClient()),
        authNotifierProvider.overrideWith(_Auth.new),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the dialog from the Free screen the backend has codes for.
Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('promo_entry')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('US-PROMO-01: the row shows for a Free account with codes', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeSubscriptionRepository(),
      freeWithCodesSnapshot,
    );
    expect(find.text('Redeem a code'), findsOneWidget);
  });

  testWidgets('US-PROMO-01: no row when the backend has no codes', (
    tester,
  ) async {
    await _pump(tester, FakeSubscriptionRepository(), freeSnapshot);
    expect(find.text('Redeem a code'), findsNothing);
  });

  testWidgets('US-PROMO-01: no row on Pro, where a code would add nothing', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeSubscriptionRepository(),
      SubscriptionSnapshot(
        entitlements: proSnapshot.entitlements,
        status: proSnapshot.status,
        promoAvailable: true,
      ),
    );
    expect(find.text('Redeem a code'), findsNothing);
  });

  testWidgets('US-PROMO-01: Redeem stays disabled until a code is typed', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeSubscriptionRepository(),
      freeWithCodesSnapshot,
    );
    await _openDialog(tester);

    final button = find.byKey(const Key('promo_redeem_submit'));
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('promo_code_field')), '  ');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('promo_code_field')), 'LAUNCH30');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('US-PROMO-01: redeeming shows Pro, its end date and the source', (
    tester,
  ) async {
    final repo = FakeSubscriptionRepository()
      ..promoResult = Ok(promoProSnapshot());
    await _pump(tester, repo, freeWithCodesSnapshot);
    expect(find.text('Free'), findsOneWidget);

    await _openDialog(tester);
    await tester.enterText(
      find.byKey(const Key('promo_code_field')),
      ' LAUNCH30 ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('promo_redeem_submit')));
    await tester.pumpAndSettle();

    // Trimmed before it leaves the app; the server does the same again.
    expect(repo.redeemedCodes, ['LAUNCH30']);
    // The dialog closed and the plan is the one the backend granted.
    expect(find.byKey(const Key('promo_code_field')), findsNothing);
    expect(find.text('JobTrigger Pro'), findsOneWidget);
    // The plan card shows the label and the date as two rows.
    expect(find.text('Ends on'), findsOneWidget);
    expect(find.text('15 Jan 2027'), findsOneWidget);
    expect(find.text('Redeemed with a code.'), findsOneWidget);
    // Pro no longer offers the action.
    expect(find.text('Redeem a code'), findsNothing);
  });

  testWidgets('US-PROMO-01: a refused code shows its sentence and stays open', (
    tester,
  ) async {
    final repo = FakeSubscriptionRepository()
      ..promoResult = const Err(
        StudentRequestFailure(
          409,
          'already_redeemed',
          "You've already used that code.",
        ),
      );
    await _pump(tester, repo, freeWithCodesSnapshot);
    await _openDialog(tester);
    await tester.enterText(
      find.byKey(const Key('promo_code_field')),
      'LAUNCH30',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('promo_redeem_submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('promo_code_field')), findsOneWidget);
    expect(find.text("You've already used that code."), findsOneWidget);
    // The screen's row is still there behind the dialog, and the plan is Free.
    expect(find.byKey(const Key('promo_entry')), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
  });

  testWidgets('US-PROMO-01: a network failure says Try again and sends once', (
    tester,
  ) async {
    final repo = FakeSubscriptionRepository()
      ..promoResult = const Err(NetworkFailure());
    await _pump(tester, repo, freeWithCodesSnapshot);
    await _openDialog(tester);
    await tester.enterText(
      find.byKey(const Key('promo_code_field')),
      'LAUNCH30',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('promo_redeem_submit')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Can't reach the server. Check your connection and try again.",
      ),
      findsOneWidget,
    );
    expect(repo.redeemedCodes, hasLength(1));
  });

  test('US-PROMO-01: demo mode never sends a code', () async {
    final repo = FakeSubscriptionRepository();
    final container = ProviderContainer(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(repo),
        demoModeInitialProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    final outcome = await container.read(promoRedeemProvider.notifier).redeem(
      'LAUNCH30',
    );
    expect(outcome, isA<PromoRedeemRefused>());
    expect(repo.redeemedCodes, isEmpty);
  });

  test('US-PROMO-01: a double tap sends one request', () async {
    final repo = FakeSubscriptionRepository()..promoResult = Ok(promoProSnapshot());
    final container = ProviderContainer(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(promoRedeemProvider.notifier);

    final first = notifier.redeem('LAUNCH30');
    final second = notifier.redeem('LAUNCH30');
    expect(await second, isA<PromoRedeemBusy>());
    expect(await first, isA<PromoRedeemed>());
    expect(repo.redeemedCodes, hasLength(1));
  });

  test('US-PROMO-01: the granted snapshot is the plan the code gave', () async {
    final repo = FakeSubscriptionRepository()..promoResult = Ok(promoProSnapshot());
    final container = ProviderContainer(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final outcome = await container.read(promoRedeemProvider.notifier).redeem(
      'LAUNCH30',
    );
    expect(outcome, isA<PromoRedeemed>());
    final snapshot = (outcome as PromoRedeemed).snapshot;
    expect(snapshot.entitlements.isPro, isTrue);
    expect(snapshot.status.isPromo, isTrue);
    expect(snapshot.status.periodEnd, DateTime.utc(2027, 1, 15, 12));
  });
}
