import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/no_retry.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/package_info_provider.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/billing/revenuecat_billing_client.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/data/repositories/admin_review_repository_impl.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/admin_review/admin_student_application.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/admin_review/admin_access_provider.dart';
import 'package:job_trigger/presentation/features/admin_review/admin_applications_screen.dart';
import 'package:job_trigger/presentation/features/app_info/app_info_notifier.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/home/reachability_watcher.dart';
import 'package:job_trigger/presentation/features/profile/profile_screen.dart';
import 'package:job_trigger/presentation/features/subscription/billing_availability.dart';
import 'package:job_trigger/presentation/features/subscription/entitlements_notifier.dart';
import 'package:job_trigger/presentation/navigation/app_router.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_admin_review.dart';
import '../../../support/fake_subscription.dart';

class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'a1', email: 'developer@jobtrigger.app'));
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

/// The Profile screen, billing off (no store keys), with [access].
Future<void> _profile(
  WidgetTester tester,
  Result<bool, AppFailure> access,
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
      GoRoute(
        path: AppRoutes.adminStudentApplications,
        builder: (_, _) => const Scaffold(body: Text('applications screen')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: noRetry,
      overrides: [
        authNotifierProvider.overrideWith(_Auth.new),
        activeServerNotifierProvider.overrideWith(_Server.new),
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot)),
        ),
        billingClientProvider.overrideWithValue(
          FakeBillingClient(configured: false),
        ),
        adminReviewRepositoryProvider.overrideWithValue(
          FakeAdminReviewRepository(access: access),
        ),
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
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('Profile row (US-STU-02)', () {
    testWidgets('a super admin sees "Student applications", with billing '
        'off, and it opens the screen', (tester) async {
      await _profile(tester, const Ok(true));
      expect(find.text('Subscription'), findsNothing, reason: 'billing off');
      expect(find.text('Student applications'), findsOneWidget);
      await tester.tap(find.text('Student applications'));
      await tester.pumpAndSettle();
      expect(find.text('applications screen'), findsOneWidget);
    });

    testWidgets('anyone else, or a failed check, sees no row', (tester) async {
      await _profile(tester, const Ok(false));
      expect(find.text('Student applications'), findsNothing);
      expect(find.text('Change password'), findsOneWidget);
    });

    testWidgets('a failed check shows no row', (tester) async {
      await _profile(tester, const Err(NetworkFailure()));
      expect(find.text('Student applications'), findsNothing);
    });
  });

  group('routes (US-STU-02)', () {
    Future<ProviderContainer> signedIn(
      WidgetTester tester,
      FakeAdminReviewRepository repo,
    ) async {
      final container = ProviderContainer(
        retry: noRetry,
        overrides: [
          credentialsNotifierProvider.overrideWith(_NoCredentials.new),
          appInfoNotifierProvider.overrideWith(_Info.new),
          reachabilityWatcherProvider.overrideWith((ref) {}),
          subscriptionRepositoryProvider.overrideWithValue(
            FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot)),
          ),
          billingClientProvider.overrideWithValue(
            FakeBillingClient(configured: false),
          ),
          adminReviewRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(authNotifierProvider, (_, _) {});
      container.listen(entitlementsNotifierProvider, (_, _) {});
      await container
          .read(authNotifierProvider.notifier)
          .setSession(
            const User(id: 'a1', email: 'developer@jobtrigger.app'),
            'jwt-abc',
          );
      await container.read(entitlementsNotifierProvider.future);
      await container.read(adminAccessProvider.future);
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

    testWidgets('not a super admin: both routes go Home', (tester) async {
      final container = await signedIn(
        tester,
        FakeAdminReviewRepository(access: const Ok(false)),
      );
      final router = container.read(appRouterProvider);
      router.go(AppRoutes.adminStudentApplications);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.home,
      );
      router.go(AppRoutes.adminStudentApplication, extra: 'e1');
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.home,
      );
      expect(find.byType(AdminApplicationsScreen), findsNothing);
    });

    testWidgets('a super admin reaches the screen with billing off', (
      tester,
    ) async {
      final container = await signedIn(
        tester,
        FakeAdminReviewRepository(
          lists: {
            AdminStatusFilter.pending: Ok([pendingEmail]),
          },
        ),
      );
      expect(container.read(billingAvailableProvider), isFalse);
      final router = container.read(appRouterProvider);
      router.go(AppRoutes.adminStudentApplications);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.adminStudentApplications,
      );
      expect(find.byType(AdminApplicationsScreen), findsOneWidget);
      expect(find.text('kasun@uom.ac.lk'), findsOneWidget);
    });

    testWidgets('the detail route without its id goes Home', (tester) async {
      final container = await signedIn(tester, FakeAdminReviewRepository());
      final router = container.read(appRouterProvider);
      router.go(AppRoutes.adminStudentApplication);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.home,
      );
    });
  });
}
