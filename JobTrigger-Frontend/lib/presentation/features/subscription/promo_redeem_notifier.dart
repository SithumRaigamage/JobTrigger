import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/demo/demo_mode_notifier.dart';
import '../../../data/repositories/subscription_repository_impl.dart';
import '../../../domain/subscription/subscription_status.dart';

part 'promo_redeem_notifier.g.dart';

/// What redeeming a promo or voucher code came to (US-PROMO-01). The dialog
/// maps it to copy; [PromoRedeemBusy] is a second tap while one is already
/// in flight and shows nothing.
sealed class PromoRedeemOutcome {
  const PromoRedeemOutcome();
}

final class PromoRedeemed extends PromoRedeemOutcome {
  const PromoRedeemed(this.snapshot);

  /// The plan the code granted, exactly as `GET /api/subscription` would say.
  final SubscriptionSnapshot snapshot;
}

/// The backend refused the code. [message] is its own sentence; [code] is
/// `invalid_code`, `already_redeemed`, `already_pro` or `not_available`.
final class PromoRedeemRefused extends PromoRedeemOutcome {
  const PromoRedeemRefused(this.message, {this.code});

  final String message;
  final String? code;
}

final class PromoRedeemFailed extends PromoRedeemOutcome {
  const PromoRedeemFailed(this.failure);

  final AppFailure failure;
}

final class PromoRedeemBusy extends PromoRedeemOutcome {
  const PromoRedeemBusy();
}

/// US-PROMO-01: one redemption at a time, never from demo mode.
@riverpod
class PromoRedeem extends _$PromoRedeem {
  bool _busy = false;

  @override
  void build() {}

  /// Redeems [code]. The repository call is the only way Pro is granted: the
  /// code is checked on the server, never here.
  Future<PromoRedeemOutcome> redeem(String code) async {
    if (_busy) return const PromoRedeemBusy();
    // E2: demo mode never reaches the backend, and has no plan to change.
    if (ref.read(demoModeNotifierProvider)) {
      return const PromoRedeemRefused(
        'Promo codes are not available in demo mode.',
      );
    }
    _busy = true;
    try {
      final result = await ref
          .read(subscriptionRepositoryProvider)
          .redeemPromoCode(code.trim());
      switch (result) {
        case Ok(:final value):
          return PromoRedeemed(value);
        case Err(error: final failure):
          return failure is StudentRequestFailure
              ? PromoRedeemRefused(failure.serverMessage, code: failure.code)
              : PromoRedeemFailed(failure);
      }
    } finally {
      _busy = false;
    }
  }
}
