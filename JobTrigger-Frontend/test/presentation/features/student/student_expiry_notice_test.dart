import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/billing/revenuecat_billing_client.dart';
import 'package:job_trigger/data/demo/demo_mode_notifier.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/subscription/entitlements.dart';
import 'package:job_trigger/domain/subscription/subscription_status.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/student/student_expiry_notice.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_subscription.dart';

class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u1', email: 'a@b.dev'));
}

SubscriptionSnapshot _student(DateTime? end, {SubscriptionSource? source}) =>
    SubscriptionSnapshot(
      entitlements: proSnapshot.entitlements,
      status: SubscriptionStatus(
        state: SubscriptionState.active,
        source: source ?? SubscriptionSource.student,
        periodEnd: end,
      ),
    );

Future<void> _pump(
  WidgetTester tester,
  SubscriptionSnapshot snapshot, {
  bool hasKey = true,
  bool demo = false,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: StudentExpiryBanner()),
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
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(loadResult: Ok(snapshot)),
        ),
        billingClientProvider.overrideWithValue(
          FakeBillingClient(configured: hasKey),
        ),
        demoModeInitialProvider.overrideWithValue(demo),
        authNotifierProvider.overrideWith(_Auth.new),
      ],
      child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('studentYearEndingSoon', () {
    final now = DateTime(2027, 6, 1, 12);
    SubscriptionSnapshot at(Duration left) => _student(now.add(left));

    test('is the end date inside the last 7 days', () {
      expect(
        at(const Duration(days: 7)).studentYearEndingSoon(now),
        now.add(const Duration(days: 7)),
      );
      expect(at(const Duration(days: 1)).studentYearEndingSoon(now), isNotNull);
    });

    test('is null earlier, at the end, and after it', () {
      expect(at(const Duration(days: 8)).studentYearEndingSoon(now), isNull);
      expect(at(Duration.zero).studentYearEndingSoon(now), isNull);
      expect(at(const Duration(days: -1)).studentYearEndingSoon(now), isNull);
    });

    test('is null for any other plan, Free, or billing off', () {
      final soon = now.add(const Duration(days: 3));
      expect(
        _student(
          soon,
          source: SubscriptionSource.appStore,
        ).studentYearEndingSoon(now),
        isNull,
      );
      expect(freeSnapshot.studentYearEndingSoon(now), isNull);
      expect(_student(null).studentYearEndingSoon(now), isNull);
      expect(
        SubscriptionSnapshot(
          entitlements: Entitlements.unrestricted,
          status: SubscriptionStatus(
            state: SubscriptionState.active,
            source: SubscriptionSource.student,
            periodEnd: soon,
          ),
        ).studentYearEndingSoon(now),
        isNull,
      );
    });
  });

  group('StudentExpiryBanner', () {
    testWidgets('shows the end date in the last 7 days, and opens the '
        'Subscription screen', (tester) async {
      await _pump(
        tester,
        _student(DateTime.now().add(const Duration(days: 3))),
      );
      expect(find.text('Your student year ends soon'), findsOneWidget);
      expect(find.textContaining('Your free Pro year ends on'), findsOneWidget);
      expect(find.textContaining("you're on the Free plan"), findsOneWidget);

      await tester.tap(find.byKey(const Key('student_expiry_banner')));
      await tester.pumpAndSettle();
      expect(find.text('subscription screen'), findsOneWidget);
    });

    testWidgets('is hidden with more than 7 days left', (tester) async {
      await _pump(
        tester,
        _student(DateTime.now().add(const Duration(days: 30))),
      );
      expect(find.byKey(const Key('student_expiry_banner')), findsNothing);
    });

    testWidgets('is hidden once the year has ended', (tester) async {
      await _pump(
        tester,
        _student(DateTime.now().subtract(const Duration(hours: 1))),
      );
      expect(find.byKey(const Key('student_expiry_banner')), findsNothing);
    });

    testWidgets('is hidden for a paying subscriber near the end of a term', (
      tester,
    ) async {
      await _pump(
        tester,
        _student(
          DateTime.now().add(const Duration(days: 3)),
          source: SubscriptionSource.appStore,
        ),
      );
      expect(find.byKey(const Key('student_expiry_banner')), findsNothing);
    });

    testWidgets('is hidden in a build with no billing key', (tester) async {
      await _pump(
        tester,
        _student(DateTime.now().add(const Duration(days: 3))),
        hasKey: false,
      );
      expect(find.byKey(const Key('student_expiry_banner')), findsNothing);
    });

    testWidgets('is hidden in demo mode', (tester) async {
      await _pump(
        tester,
        _student(DateTime.now().add(const Duration(days: 3))),
        demo: true,
      );
      expect(find.byKey(const Key('student_expiry_banner')), findsNothing);
    });
  });
}
