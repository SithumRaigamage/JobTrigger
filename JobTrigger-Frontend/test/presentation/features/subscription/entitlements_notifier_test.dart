import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/billing/revenuecat_billing_client.dart';
import 'package:job_trigger/data/demo/demo_mode_notifier.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/subscription/entitlements.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/entitlements_notifier.dart';

import '../../../support_subscription_fakes.dart';

class _Auth extends AuthNotifier {
  _Auth(this.initial);

  final AuthState initial;

  @override
  Future<AuthState> build() async => initial;

  void signOut() => state = const AsyncData(Unauthenticated());
}

const _signedIn = Authenticated(User(id: 'u1', email: 'a@b.dev'));

ProviderContainer _container({
  required FakeSubscriptionRepository repo,
  AuthState auth = _signedIn,
  FakeBillingClient? billing,
  bool demo = false,
}) {
  final container = ProviderContainer(
    overrides: [
      subscriptionRepositoryProvider.overrideWithValue(repo),
      billingClientProvider.overrideWithValue(
        billing ?? FakeBillingClient(configured: false),
      ),
      authNotifierProvider.overrideWith(() => _Auth(auth)),
      demoModeInitialProvider.overrideWithValue(demo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('before any answer the entitlements restrict nothing', () {
    final container = _container(repo: FakeSubscriptionRepository());
    expect(container.read(entitlementsProvider), Entitlements.unrestricted);
  });

  test('signed in with no cache: the loaded plan is used', () async {
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot));
    final container = _container(repo: repo);

    await container.read(entitlementsNotifierProvider.future);

    expect(container.read(entitlementsProvider).plan, Plan.free);
    expect(repo.loads, 1);
  });

  test('a cached plan is used at once, then freshened in the background',
      () async {
    final repo = FakeSubscriptionRepository(
      cachedValue: freeSnapshot,
      loadResult: const Ok(proSnapshot),
    );
    final container = _container(repo: repo);
    container.listen(entitlementsNotifierProvider, (_, _) {});

    final first = await container.read(entitlementsNotifierProvider.future);
    expect(first.entitlements.plan, Plan.free);

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(entitlementsProvider).plan, Plan.pro);
  });

  test('an unreachable backend or an old one keeps the app unrestricted',
      () async {
    final repo = FakeSubscriptionRepository(
      loadResult: const Err(NotFoundFailure()),
    );
    final container = _container(repo: repo);

    await container.read(entitlementsNotifierProvider.future);

    expect(container.read(entitlementsProvider), Entitlements.unrestricted);
  });

  test('a failed refresh keeps what is shown', () async {
    final repo = FakeSubscriptionRepository(
      cachedValue: freeSnapshot,
      loadResult: const Err(NetworkFailure()),
    );
    final container = _container(repo: repo);
    container.listen(entitlementsNotifierProvider, (_, _) {});
    await container.read(entitlementsNotifierProvider.future);
    await container.read(entitlementsNotifierProvider.notifier).refresh();

    expect(container.read(entitlementsProvider).plan, Plan.free);
  });

  test('signed out or in demo mode: no request, nothing restricted', () async {
    for (final scenario in [
      (const Unauthenticated() as AuthState, false),
      (_signedIn as AuthState, true),
    ]) {
      final repo = FakeSubscriptionRepository(
        loadResult: const Ok(freeSnapshot),
      );
      final container = _container(
        repo: repo,
        auth: scenario.$1,
        demo: scenario.$2,
      );
      await container.read(authNotifierProvider.future);
      await container.read(entitlementsNotifierProvider.future);

      expect(container.read(entitlementsProvider), Entitlements.unrestricted);
      expect(repo.loads, 0);
    }
  });

  test('apply replaces the answer, e.g. after a purchase', () async {
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot));
    final container = _container(repo: repo);
    await container.read(entitlementsNotifierProvider.future);

    container.read(entitlementsNotifierProvider.notifier).apply(proSnapshot);

    expect(container.read(entitlementsProvider).isPro, isTrue);
  });

  test('coming back to the foreground reloads the plan', () async {
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot));
    final container = _container(repo: repo);
    container.listen(entitlementsNotifierProvider, (_, _) {});
    await container.read(entitlementsNotifierProvider.future);
    expect(repo.loads, 1);

    repo.loadResult = const Ok(proSnapshot);
    TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await Future<void>.delayed(Duration.zero);

    expect(repo.loads, 2);
    expect(container.read(entitlementsProvider).plan, Plan.pro);
  });

  test('signing out drops back to unrestricted without a request', () async {
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot));
    final container = _container(repo: repo);
    container.listen(entitlementsNotifierProvider, (_, _) {});
    await container.read(entitlementsNotifierProvider.future);
    expect(container.read(entitlementsProvider).plan, Plan.free);

    (container.read(authNotifierProvider.notifier) as _Auth).signOut();
    await container.read(entitlementsNotifierProvider.future);

    expect(container.read(entitlementsProvider), Entitlements.unrestricted);
    expect(repo.loads, 1);
  });

  group('billing identity (billingSession)', () {
    test('logs the purchase SDK in with the account id and out again',
        () async {
      final billing = FakeBillingClient();
      final container = _container(
        repo: FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot)),
        billing: billing,
      );
      container.listen(entitlementsNotifierProvider, (_, _) {});
      await container.read(entitlementsNotifierProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(billing.calls, ['logIn:u1']);

      (container.read(authNotifierProvider.notifier) as _Auth).signOut();
      await Future<void>.delayed(Duration.zero);
      expect(billing.calls, ['logIn:u1', 'logOut']);
    });

    test('a build with no SDK key never touches it', () async {
      final billing = FakeBillingClient(configured: false);
      final container = _container(
        repo: FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot)),
        billing: billing,
      );
      container.listen(entitlementsNotifierProvider, (_, _) {});
      await container.read(entitlementsNotifierProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(billing.calls, isEmpty);
    });

    test('demo mode never logs in', () async {
      final billing = FakeBillingClient();
      final container = _container(
        repo: FakeSubscriptionRepository(),
        billing: billing,
        demo: true,
      );
      container.listen(entitlementsNotifierProvider, (_, _) {});
      await container.read(entitlementsNotifierProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(billing.calls, isEmpty);
    });
  });
}
