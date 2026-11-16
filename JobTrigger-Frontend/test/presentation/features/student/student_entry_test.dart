import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/package_info_provider.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/billing/revenuecat_billing_client.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/data/demo/demo_mode_notifier.dart';
import 'package:job_trigger/data/repositories/student_repository_impl.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/subscription/entitlements.dart';
import 'package:job_trigger/domain/subscription/subscription_status.dart';
import 'package:job_trigger/presentation/features/app_info/app_info_notifier.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/home/reachability_watcher.dart';
import 'package:job_trigger/presentation/features/profile/profile_screen.dart';
import 'package:job_trigger/presentation/features/student/student_verification_screen.dart';
import 'package:job_trigger/presentation/features/subscription/entitlements_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/subscription_screen.dart';
import 'package:job_trigger/presentation/navigation/app_router.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_student.dart';
import '../../../support/fake_subscription.dart';

/// Pro from the free student year, ending [end].
SubscriptionSnapshot studentSnapshot(DateTime end) => SubscriptionSnapshot(
  entitlements: proSnapshot.entitlements,
  status: SubscriptionStatus(
    state: SubscriptionState.active,
    source: SubscriptionSource.student,
    periodEnd: end,
  ),
);

class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u1', email: 'a@b.dev'));
}

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => null;
}

class _Info extends AppInfoNotifier {
  @override
  Future<AppInfo> build() async =>
      const AppInfo(appVersion: '1', buildNumber: '1');
}

class _NoCredentials extends CredentialsNotifier {
  @override
  Future<List<JenkinsServer>> build() async => const [];
}

Future<void> _pumpSubscription(
  WidgetTester tester,
  SubscriptionSnapshot snapshot,
) async {
  tester.view.physicalSize = const Size(800, 1800);
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
        path: AppRoutes.studentVerification,
        builder: (_, _) => const Scaffold(body: Text('student screen')),
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
        authNotifierProvider.overrideWith(_Auth.new),
      ],
      child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpProfile(
  WidgetTester tester,
  SubscriptionSnapshot snapshot,
) async {
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
        billingClientProvider.overrideWithValue(FakeBillingClient()),
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
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ProfileScreen)),
  );
  container.listen(entitlementsNotifierProvider, (_, _) {});
  await container.read(entitlementsNotifierProvider.future);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('Subscription screen entry', () {
    testWidgets('a Free user is offered "Verify student status"', (
      tester,
    ) async {
      await _pumpSubscription(tester, freeSnapshot);
      expect(find.text('Verify student status'), findsOneWidget);
      expect(find.text('Students get Pro free for one year.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('student_entry')));
      await tester.pumpAndSettle();
      expect(find.text('student screen'), findsOneWidget);
    });

    testWidgets('a student sees the plan, the note and the date', (
      tester,
    ) async {
      await _pumpSubscription(
        tester,
        studentSnapshot(DateTime(2027, 11, 16, 12)),
      );
      expect(find.text('JobTrigger Pro'), findsOneWidget);
      expect(find.text('Ends on'), findsOneWidget);
      expect(find.text('16 Nov 2027'), findsOneWidget);
      expect(
        find.text('Free for one year as a verified student.'),
        findsOneWidget,
      );
      expect(find.text('Student status'), findsOneWidget);
      // Nothing to buy and no store link for the free year.
      expect(find.text('Upgrade to Pro'), findsNothing);
      expect(find.textContaining('Manage in the'), findsNothing);
    });

    testWidgets('a paying subscriber is not offered the student plan', (
      tester,
    ) async {
      await _pumpSubscription(tester, storeProSnapshot());
      expect(find.byKey(const Key('student_entry')), findsNothing);
    });
  });

  group('Profile', () {
    testWidgets('a student sees "Pro (Student)" and the expiry date', (
      tester,
    ) async {
      await _pumpProfile(tester, studentSnapshot(DateTime(2027, 11, 16, 12)));
      expect(find.text('Pro (Student)'), findsOneWidget);
      expect(find.text('Student plan until 16 Nov 2027'), findsOneWidget);
    });

    testWidgets('Pro bought normally still reads just "Pro"', (tester) async {
      await _pumpProfile(tester, storeProSnapshot());
      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('Pro (Student)'), findsNothing);
      expect(find.textContaining('Student plan until'), findsNothing);
    });

    testWidgets('Free reads "Free" with no student line', (tester) async {
      await _pumpProfile(tester, freeSnapshot);
      expect(find.text('Free'), findsOneWidget);
      expect(find.textContaining('Student plan until'), findsNothing);
    });
  });

  group('planLabelFor', () {
    test('only the student year changes the label', () {
      final student = studentSnapshot(DateTime(2027));
      expect(planLabelFor(student.entitlements, student), 'Pro (Student)');
      expect(planLabelFor(proSnapshot.entitlements, proSnapshot), 'Pro');
      expect(planLabelFor(freeSnapshot.entitlements, freeSnapshot), 'Free');
      expect(planLabelFor(Entitlements.unrestricted, null), 'Pro');
    });
  });

  group('route', () {
    Future<ProviderContainer> signedIn(
      WidgetTester tester, {
      required bool hasKey,
      bool demo = false,
    }) async {
      final container = ProviderContainer(
        overrides: [
          credentialsNotifierProvider.overrideWith(_NoCredentials.new),
          appInfoNotifierProvider.overrideWith(_Info.new),
          reachabilityWatcherProvider.overrideWith((ref) {}),
          subscriptionRepositoryProvider.overrideWithValue(
            FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot)),
          ),
          studentRepositoryProvider.overrideWithValue(FakeStudentRepository()),
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
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: container.read(appRouterProvider),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('unreachable in a default build (no billing): goes Home', (
      tester,
    ) async {
      final container = await signedIn(tester, hasKey: false);
      final router = container.read(appRouterProvider);
      router.go(AppRoutes.studentVerification);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.home,
      );
      expect(find.byType(StudentVerificationScreen), findsNothing);
    });

    testWidgets('unreachable in demo mode', (tester) async {
      final container = await signedIn(tester, hasKey: true, demo: true);
      final router = container.read(appRouterProvider);
      router.go(AppRoutes.studentVerification);
      await tester.pumpAndSettle();
      expect(find.byType(StudentVerificationScreen), findsNothing);
    });

    testWidgets('opens when billing is available', (tester) async {
      final container = await signedIn(tester, hasKey: true);
      container.read(appRouterProvider).go(AppRoutes.studentVerification);
      await tester.pumpAndSettle();
      expect(find.byType(StudentVerificationScreen), findsOneWidget);
    });
  });
}
