import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/theme/app_colors.dart';
import '../../common_widgets/inline_alert.dart';
import '../../navigation/app_routes.dart';
import 'entitlements_notifier.dart';
import 'promo_expiry_reminder.dart';

part 'promo_expiry_notice.g.dart';

/// US-PROMO-06: when Pro from a redeemed code ends within three days, that end
/// date; otherwise null. Read from the plan the app already has, so it needs
/// no request.
///
/// This is the reminder's other half, and the one that works for the many
/// people who never allowed notifications: a local notification cannot reach
/// them, so the end of Pro is also said on the screen. No billing-availability
/// gate here — the plan itself already says billing is on and the source is a
/// promo code, and demo mode never has one.
@riverpod
DateTime? promoExpiryNotice(Ref ref) {
  final snapshot = ref.watch(entitlementsNotifierProvider).value;
  return snapshot?.promoEndingSoon(DateTime.now());
}

/// The banner for [promoExpiryNoticeProvider]: the day the code's Pro ends,
/// what follows, and the way to redeem another code. Tapping opens the
/// Subscription screen.
class PromoExpiryBanner extends ConsumerWidget {
  const PromoExpiryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final end = ref.watch(promoExpiryNoticeProvider);
    if (end == null) return const SizedBox.shrink();
    return Padding(
      key: const Key('promo_expiry_banner'),
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        button: true,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: () => context.push(AppRoutes.subscription),
          child: InlineAlert(
            icon: Icons.confirmation_number_outlined,
            tone: StatusTone.unstable,
            title: 'Your Pro from a code ends soon',
            message:
                'Pro from your code ends on '
                '${formatPromoDate(end.toLocal())}. After that you\'re on '
                'the Free plan. Tap to redeem another code.',
          ),
        ),
      ),
    );
  }
}
