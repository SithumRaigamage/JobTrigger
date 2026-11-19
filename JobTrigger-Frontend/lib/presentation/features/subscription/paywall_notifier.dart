import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/no_retry.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/subscription_repository_impl.dart';
import '../../../domain/subscription/billing_offer.dart';
import '../../../domain/subscription/subscription_status.dart';
import 'entitlements_notifier.dart';

part 'paywall_notifier.g.dart';

class PaywallState {
  const PaywallState({required this.offers, this.busy = false});

  final List<BillingOffer> offers;

  /// A purchase or restore is in progress.
  final bool busy;

  PaywallState copyWith({bool? busy}) =>
      PaywallState(offers: offers, busy: busy ?? this.busy);
}

/// What a purchase or restore came to. The screen maps it to copy; a
/// [PaywallCancelled] shows nothing at all.
sealed class PaywallOutcome {
  const PaywallOutcome();
}

final class PaywallPurchased extends PaywallOutcome {
  const PaywallPurchased();
}

/// The store accepted the purchase but no Pro entitlement is active yet.
/// Normal for Google Play's "pending" purchases (cash, bank transfer): the
/// store confirms later and the webhook/refresh turns Pro on.
final class PaywallPending extends PaywallOutcome {
  const PaywallPending();
}

final class PaywallRestored extends PaywallOutcome {
  const PaywallRestored();
}

/// Restore worked but this store account has no active subscription.
final class PaywallNothingToRestore extends PaywallOutcome {
  const PaywallNothingToRestore();
}

/// The user closed the store sheet: not an error, shown as nothing.
final class PaywallCancelled extends PaywallOutcome {
  const PaywallCancelled();
}

final class PaywallFailed extends PaywallOutcome {
  const PaywallFailed(this.failure);

  final AppFailure failure;
}

/// P20-23: loads the store's offers and runs a purchase or restore. After
/// either, asks the backend to re-read the subscription
/// (`POST /api/subscription/refresh`) and hands the answer to
/// [EntitlementsNotifier], so Pro unlocks without waiting for the webhook.
@Riverpod(retry: noRetry)
class PaywallNotifier extends _$PaywallNotifier {
  @override
  Future<PaywallState> build() async {
    final result = await ref.read(subscriptionRepositoryProvider).offerings();
    return switch (result) {
      Ok(:final value) => PaywallState(offers: value),
      Err(:final error) => throw error,
    };
  }

  Future<PaywallOutcome> purchase(BillingOffer offer) async {
    final current = state.value;
    if (current == null || current.busy) return const PaywallCancelled();
    state = AsyncData(current.copyWith(busy: true));
    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      final bought = await repository.purchase(offer);
      if (bought case Err(:final error)) {
        return error is PurchaseCancelled
            ? const PaywallCancelled()
            : PaywallFailed(error);
      }
      // Ask the backend, which re-reads the store, whether Pro is active.
      final synced = await _syncEntitlements();
      if (synced == null) {
        // The store said yes and the backend couldn't be asked. Assume the
        // purchase; the webhook and the next refresh catch up.
        return const PaywallPurchased();
      }
      // A completed purchase activates `pro` immediately. No entitlement
      // means the store still has it pending (Play's deferred payment), so
      // don't claim Pro is active.
      return synced.entitlements.isPro
          ? const PaywallPurchased()
          : const PaywallPending();
    } finally {
      if (ref.mounted) state = AsyncData(current.copyWith(busy: false));
    }
  }

  Future<PaywallOutcome> restore() async {
    final current = state.value;
    if (current == null || current.busy) return const PaywallCancelled();
    state = AsyncData(current.copyWith(busy: true));
    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      final restored = await repository.restore();
      if (restored case Err(:final error)) {
        return error is PurchaseCancelled
            ? const PaywallCancelled()
            : PaywallFailed(error);
      }
      final synced = await repository.refresh();
      switch (synced) {
        case Err(:final error):
          return PaywallFailed(error);
        case Ok(:final value):
          if (ref.mounted) {
            ref.read(entitlementsNotifierProvider.notifier).apply(value);
          }
          return value.entitlements.isPro
              ? const PaywallRestored()
              : const PaywallNothingToRestore();
      }
    } finally {
      if (ref.mounted) state = AsyncData(current.copyWith(busy: false));
    }
  }

  /// The plan after a purchase, or null when the backend couldn't be
  /// reached (the cached/loaded plan is kept in that case).
  Future<SubscriptionSnapshot?> _syncEntitlements() async {
    final synced = await ref.read(subscriptionRepositoryProvider).refresh();
    if (!ref.mounted) return null;
    if (synced case Ok(:final value)) {
      ref.read(entitlementsNotifierProvider.notifier).apply(value);
      return value;
    }
    await ref.read(entitlementsNotifierProvider.notifier).refresh();
    return null;
  }
}
