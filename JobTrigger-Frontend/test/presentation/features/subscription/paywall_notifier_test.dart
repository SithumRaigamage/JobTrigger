import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/billing/revenuecat_billing_client.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/subscription/entitlements.dart';
import 'package:job_trigger/domain/subscription/subscription_status.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/entitlements_notifier.dart';
import 'package:job_trigger/presentation/features/subscription/paywall_notifier.dart';

import '../../../support/fake_subscription.dart';

class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u1', email: 'a@b.dev'));
}

Future<(ProviderContainer, FakeSubscriptionRepository)> _setup({
  required Result<SubscriptionSnapshot, AppFailure> load,
}) async {
  final repo = FakeSubscriptionRepository(loadResult: load);
  final container = ProviderContainer(
    overrides: [
      subscriptionRepositoryProvider.overrideWithValue(repo),
      billingClientProvider.overrideWithValue(
        FakeBillingClient(configured: false),
      ),
      authNotifierProvider.overrideWith(_Auth.new),
    ],
  );
  addTearDown(container.dispose);
  container.listen(entitlementsNotifierProvider, (_, _) {});
  container.listen(paywallNotifierProvider, (_, _) {});
  await container.read(entitlementsNotifierProvider.future);
  await container.read(paywallNotifierProvider.future);
  return (container, repo);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the store offers', () async {
    final (container, _) = await _setup(load: const Ok(freeSnapshot));
    final state = container.read(paywallNotifierProvider).requireValue;
    expect(state.offers.map((o) => o.id), ['monthly', 'yearly']);
    expect(state.busy, isFalse);
  });

  test('a purchase unlocks Pro from the backend\'s refreshed answer', () async {
    final (container, repo) = await _setup(load: const Ok(freeSnapshot));
    repo.refreshResult = Ok(storeProSnapshot());
    final offer = container
        .read(paywallNotifierProvider)
        .requireValue
        .offers
        .last;

    final outcome = await container
        .read(paywallNotifierProvider.notifier)
        .purchase(offer);

    expect(outcome, isA<PaywallPurchased>());
    expect(repo.purchased, ['yearly']);
    expect(container.read(entitlementsProvider).isPro, isTrue);
    expect(container.read(paywallNotifierProvider).requireValue.busy, isFalse);
  });

  test('closing the store sheet is a silent cancel: no failure, nothing '
      'changes, no refresh', () async {
    final (container, repo) = await _setup(load: const Ok(freeSnapshot));
    repo.purchaseResult = const Err(PurchaseCancelled());
    final offer = container
        .read(paywallNotifierProvider)
        .requireValue
        .offers
        .first;

    final outcome = await container
        .read(paywallNotifierProvider.notifier)
        .purchase(offer);

    expect(outcome, isA<PaywallCancelled>());
    expect(repo.refreshes, 0);
    expect(container.read(entitlementsProvider).plan, Plan.free);
    expect(container.read(paywallNotifierProvider).requireValue.busy, isFalse);
  });

  test('a store error is reported and leaves the plan alone', () async {
    final (container, repo) = await _setup(load: const Ok(freeSnapshot));
    repo.purchaseResult = const Err(UnknownFailure('declined'));
    final offer = container
        .read(paywallNotifierProvider)
        .requireValue
        .offers
        .first;

    final outcome = await container
        .read(paywallNotifierProvider.notifier)
        .purchase(offer);

    expect(outcome, isA<PaywallFailed>());
    expect(container.read(entitlementsProvider).plan, Plan.free);
  });

  test('if the backend is unreachable after a paid purchase, it is still a '
      'purchase and the plan is re-read later', () async {
    final (container, repo) = await _setup(load: const Ok(freeSnapshot));
    repo.refreshResult = const Err(NetworkFailure());
    final offer = container
        .read(paywallNotifierProvider)
        .requireValue
        .offers
        .first;

    final outcome = await container
        .read(paywallNotifierProvider.notifier)
        .purchase(offer);

    expect(outcome, isA<PaywallPurchased>());
    // The fallback reload ran (load() once at start, once now).
    expect(repo.loads, greaterThanOrEqualTo(2));
  });

  test(
    'restore: Pro comes back, or says there is nothing to restore',
    () async {
      final (container, repo) = await _setup(load: const Ok(freeSnapshot));

      repo.refreshResult = const Ok(freeSnapshot);
      expect(
        await container.read(paywallNotifierProvider.notifier).restore(),
        isA<PaywallNothingToRestore>(),
      );

      repo.refreshResult = Ok(storeProSnapshot());
      expect(
        await container.read(paywallNotifierProvider.notifier).restore(),
        isA<PaywallRestored>(),
      );
      expect(container.read(entitlementsProvider).isPro, isTrue);
      expect(repo.restores, 2);
    },
  );

  test('offers that cannot be loaded surface as an error state', () async {
    final repo = FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot))
      ..offerResult = const Err(NetworkFailure());
    final container = ProviderContainer(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(repo),
        billingClientProvider.overrideWithValue(
          FakeBillingClient(configured: false),
        ),
        authNotifierProvider.overrideWith(_Auth.new),
      ],
    );
    addTearDown(container.dispose);
    container.listen(paywallNotifierProvider, (_, _) {});
    await expectLater(
      container.read(paywallNotifierProvider.future),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
