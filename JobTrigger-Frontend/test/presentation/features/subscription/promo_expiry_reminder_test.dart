import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/core/platform/notification_service.dart';
import 'package:job_trigger/data/billing/revenuecat_billing_client.dart';
import 'package:job_trigger/data/demo/demo_mode_notifier.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/jenkins/build_watch.dart';
import 'package:job_trigger/domain/subscription/subscription_status.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/entitlements_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/promo_expiry_notice.dart';
import 'package:job_trigger/presentation/features/subscription/promo_expiry_reminder.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_subscription.dart';

class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u1', email: 'a@b.dev'));
}

/// Records what the reminder asked the platform to show. With [allowed]
/// false it behaves like a phone where notifications were never turned on.
class _Notifications implements NotificationService {
  _Notifications({this.allowed = true});

  final bool allowed;
  final shown = <({int id, String title, String body})>[];

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => allowed;

  @override
  Future<bool> areNotificationsAllowed() async => allowed;

  @override
  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<bool> showSubscriptionAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!allowed) return false;
    shown.add((id: id, title: title, body: body));
    return true;
  }

  @override
  Future<void> show(BuildNotification notification) async {}
}

/// The platform refusing the call: the app must carry on regardless.
class _ThrowingNotifications extends _Notifications {
  @override
  Future<bool> showSubscriptionAlert({
    required int id,
    required String title,
    required String body,
  }) async => throw Exception('no notification centre');
}

/// Pro from a code ending [left] after [now].
SubscriptionSnapshot _proFrom(Duration left, DateTime now) =>
    promoProSnapshot(end: now.add(left));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final now = DateTime.utc(2027, 6, 1, 12);

  group('promoEndingSoon (US-PROMO-06)', () {
    test('is the end date inside the last three days', () {
      expect(
        _proFrom(const Duration(days: 3), now).promoEndingSoon(now),
        now.add(const Duration(days: 3)),
      );
      expect(
        _proFrom(const Duration(hours: 2), now).promoEndingSoon(now),
        isNotNull,
      );
    });

    test('is null earlier, at the end, and after it', () {
      expect(
        _proFrom(const Duration(days: 3, hours: 1), now).promoEndingSoon(now),
        isNull,
      );
      expect(_proFrom(Duration.zero, now).promoEndingSoon(now), isNull);
      expect(
        _proFrom(const Duration(days: -1), now).promoEndingSoon(now),
        isNull,
      );
    });

    test('is null for a store, website or student plan, and for Free', () {
      final soon = now.add(const Duration(days: 2));
      expect(storeProSnapshot(end: soon).promoEndingSoon(now), isNull);
      expect(webProSnapshot.promoEndingSoon(now), isNull);
      expect(
        SubscriptionSnapshot(
          entitlements: proSnapshot.entitlements,
          status: SubscriptionStatus(
            state: SubscriptionState.active,
            source: SubscriptionSource.student,
            periodEnd: soon,
          ),
        ).promoEndingSoon(now),
        isNull,
      );
      expect(freeSnapshot.promoEndingSoon(now), isNull);
    });
  });

  group('remindPromoEndingSoon (US-PROMO-06)', () {
    test('says the day Pro ends, once', () async {
      final notifications = _Notifications();
      final end = now.add(const Duration(days: 2));

      await remindPromoEndingSoon(
        promoProSnapshot(end: end),
        notifications,
        now: now,
      );

      final shown = notifications.shown.single;
      expect(shown.id, promoReminderNotificationId);
      expect(shown.title, 'Your Pro from a code ends soon');
      expect(shown.body, promoReminderBody(end));
      expect(
        (await SharedPreferences.getInstance()).getString(promoReminderPrefKey),
        end.toUtc().toIso8601String(),
      );
    });

    test(
      'never repeats the same period, however often the plan reloads',
      () async {
        final notifications = _Notifications();
        final snapshot = promoProSnapshot(
          end: now.add(const Duration(days: 1)),
        );

        for (var i = 0; i < 3; i++) {
          await remindPromoEndingSoon(snapshot, notifications, now: now);
        }

        expect(notifications.shown, hasLength(1));
      },
    );

    test('a new period is reminded about again', () async {
      final notifications = _Notifications();
      await remindPromoEndingSoon(
        promoProSnapshot(end: now.add(const Duration(days: 2))),
        notifications,
        now: now,
      );
      await remindPromoEndingSoon(
        promoProSnapshot(end: now.add(const Duration(days: 3))),
        notifications,
        now: now.add(const Duration(days: 1)),
      );

      expect(notifications.shown, hasLength(2));
    });

    test('says nothing with more than three days left, at the end, or '
        'for another source', () async {
      final notifications = _Notifications();
      await remindPromoEndingSoon(
        _proFrom(const Duration(days: 4), now),
        notifications,
        now: now,
      );
      await remindPromoEndingSoon(
        _proFrom(Duration.zero, now),
        notifications,
        now: now,
      );
      await remindPromoEndingSoon(
        _proFrom(const Duration(days: -2), now),
        notifications,
        now: now,
      );
      await remindPromoEndingSoon(
        storeProSnapshot(end: now.add(const Duration(days: 2))),
        notifications,
        now: now,
      );
      await remindPromoEndingSoon(freeSnapshot, notifications, now: now);

      expect(notifications.shown, isEmpty);
    });

    test('a platform failure is not an error for the app', () async {
      await expectLater(
        remindPromoEndingSoon(
          _proFrom(const Duration(days: 2), now),
          _ThrowingNotifications(),
          now: now,
        ),
        completes,
      );
    });

    test('marks the period only when the OS took the notification, so a '
        'refused one is announced once it is allowed', () async {
      final snapshot = promoProSnapshot(end: now.add(const Duration(days: 2)));
      final refused = _Notifications(allowed: false);

      await remindPromoEndingSoon(snapshot, refused, now: now);

      expect(refused.shown, isEmpty);
      expect(
        (await SharedPreferences.getInstance()).getString(promoReminderPrefKey),
        isNull,
        reason: 'nothing was shown, so nothing is remembered',
      );

      final allowed = _Notifications();
      await remindPromoEndingSoon(snapshot, allowed, now: now);
      expect(allowed.shown, hasLength(1));
    });

    test('a refused platform call is not remembered either', () async {
      final snapshot = promoProSnapshot(end: now.add(const Duration(days: 2)));

      await remindPromoEndingSoon(snapshot, _ThrowingNotifications(), now: now);

      expect(
        (await SharedPreferences.getInstance()).getString(promoReminderPrefKey),
        isNull,
      );
    });
  });

  group('the plan arriving (US-PROMO-06)', () {
    Future<ProviderContainer> container(
      SubscriptionSnapshot snapshot,
      _Notifications notifications,
    ) async {
      final container = ProviderContainer(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(
            FakeSubscriptionRepository(loadResult: Ok(snapshot)),
          ),
          notificationServiceProvider.overrideWithValue(notifications),
          billingClientProvider.overrideWithValue(
            FakeBillingClient(configured: false),
          ),
          demoModeInitialProvider.overrideWithValue(false),
          authNotifierProvider.overrideWith(_Auth.new),
        ],
      );
      addTearDown(container.dispose);
      await container.read(entitlementsNotifierProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return container;
    }

    test('a promo ending in two days sends one reminder', () async {
      final notifications = _Notifications();
      await container(
        promoProSnapshot(end: DateTime.now().add(const Duration(days: 2))),
        notifications,
      );

      expect(notifications.shown, hasLength(1));
    });

    test('a fresh reload of the same period sends nothing more', () async {
      final notifications = _Notifications();
      final snapshot = promoProSnapshot(
        end: DateTime.now().add(const Duration(days: 2)),
      );
      final c = await container(snapshot, notifications);
      await c.read(entitlementsNotifierProvider.notifier).refresh();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(notifications.shown, hasLength(1));
    });

    test('a phone that never allowed notifications is said it in-app: '
        'nothing is marked, nothing is posted', () async {
      final notifications = _Notifications(allowed: false);
      await container(
        promoProSnapshot(end: DateTime.now().add(const Duration(days: 2))),
        notifications,
      );

      expect(notifications.shown, isEmpty);
      expect(
        (await SharedPreferences.getInstance()).getString(promoReminderPrefKey),
        isNull,
      );
    });

    test('a promo months from its end sends nothing', () async {
      final notifications = _Notifications();
      await container(
        promoProSnapshot(end: DateTime.now().add(const Duration(days: 30))),
        notifications,
      );

      expect(notifications.shown, isEmpty);
    });

    test('a store plan ending in two days sends nothing', () async {
      final notifications = _Notifications();
      await container(
        storeProSnapshot(end: DateTime.now().add(const Duration(days: 2))),
        notifications,
      );

      expect(notifications.shown, isEmpty);
    });
  });

  group('PromoExpiryBanner (US-PROMO-06)', () {
    Future<void> pump(
      WidgetTester tester,
      SubscriptionSnapshot snapshot,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: PromoExpiryBanner()),
          ),
          GoRoute(
            path: AppRoutes.subscription,
            builder: (_, _) =>
                const Scaffold(body: Text('subscription screen')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(
              FakeSubscriptionRepository(loadResult: Ok(snapshot)),
            ),
            notificationServiceProvider.overrideWithValue(_Notifications()),
            billingClientProvider.overrideWithValue(
              FakeBillingClient(configured: false),
            ),
            demoModeInitialProvider.overrideWithValue(false),
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

    testWidgets(
      'says the end date in the last three days — the reminder for a phone '
      'with no notifications — and opens the Subscription screen',
      (tester) async {
        final end = DateTime.now().add(const Duration(days: 2));
        await pump(tester, promoProSnapshot(end: end));

        expect(find.byKey(const Key('promo_expiry_banner')), findsOneWidget);
        expect(find.text('Your Pro from a code ends soon'), findsOneWidget);
        expect(
          find.textContaining('ends on ${formatPromoDate(end.toLocal())}'),
          findsOneWidget,
        );
        expect(find.textContaining("you're on the Free plan"), findsOneWidget);

        await tester.tap(find.byKey(const Key('promo_expiry_banner')));
        await tester.pumpAndSettle();
        expect(find.text('subscription screen'), findsOneWidget);
      },
    );

    testWidgets('is hidden with more than three days left', (tester) async {
      await pump(
        tester,
        promoProSnapshot(end: DateTime.now().add(const Duration(days: 7))),
      );
      expect(find.byKey(const Key('promo_expiry_banner')), findsNothing);
    });

    testWidgets('is hidden for a store plan, and once the period is over', (
      tester,
    ) async {
      await pump(
        tester,
        storeProSnapshot(end: DateTime.now().add(const Duration(days: 2))),
      );
      expect(find.byKey(const Key('promo_expiry_banner')), findsNothing);

      await pump(
        tester,
        promoProSnapshot(
          end: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      );
      expect(find.byKey(const Key('promo_expiry_banner')), findsNothing);
    });
  });
}
