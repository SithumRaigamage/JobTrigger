import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/subscription/billing_offer.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/external_link.dart';
import '../../common_widgets/grouped_card.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/toast_controller.dart';
import '../../navigation/app_routes.dart';
import '../app_info/app_info_notifier.dart';
import 'entitlements_notifier.dart';
import 'paywall_notifier.dart';
import 'paywall_reason.dart';
import 'store_links.dart';

/// P20-23: the Pro paywall (`/paywall?reason=<limit>`). Our own widget, not
/// the SDK's. It carries what both stores require: the store's localised
/// price, the period and what a trial converts to, the auto-renew notice,
/// links to Terms and Privacy, and a visible Restore action. It sells only
/// through the store; it never links to the website's checkout (App Review
/// rules). Reachable only when `billingAvailableProvider` is true.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.reason});

  /// Why the user got here, for the headline.
  final String? reason;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(entitlementsNotifierProvider).value;
    final paywall = ref.watch(paywallNotifierProvider);
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final store = storeNameFor(defaultTargetPlatform);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 26),
                    tooltip: 'Close',
                    onPressed: _close,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ResponsiveCenter(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        paywallHeadline(widget.reason),
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final benefit in proBenefits)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 20,
                              color: t.success.foreground,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(benefit, style: textTheme.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (snapshot != null && snapshot.isWebPro)
                      const InlineAlert(
                        // P20-84: Pro from the website is Pro. Nothing to
                        // buy here, and no link to buy elsewhere.
                        message:
                            'You already have Pro. It was bought on the '
                            'JobTrigger website, and is managed there.',
                        icon: Icons.verified_outlined,
                      )
                    else if (snapshot != null && snapshot.entitlements.isPro)
                      const InlineAlert(
                        message: 'You already have Pro.',
                        icon: Icons.verified_outlined,
                      )
                    else
                      ...paywall.when(
                        data: (state) => _offers(context, state, store),
                        loading: () => const [
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ],
                        error: (error, _) => [
                          ConnectionErrorView(
                            message: describeError(error),
                            onRetry: () =>
                                ref.invalidate(paywallNotifierProvider),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    _legalLinks(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _offers(BuildContext context, PaywallState state, String store) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    if (state.offers.isEmpty) {
      return [
        const InlineAlert(
          message:
              'Subscriptions are not available right now. Try again later.',
          icon: Icons.info_outline_rounded,
        ),
      ];
    }
    final selected = state.offers.firstWhere(
      (o) => o.id == _selectedId,
      orElse: () => state.offers.firstWhere(
        (o) => o.period == BillingPeriod.yearly,
        orElse: () => state.offers.first,
      ),
    );
    return [
      RadioGroup<String>(
        groupValue: selected.id,
        onChanged: (value) {
          if (!state.busy && value != null) setState(() => _selectedId = value);
        },
        child: GroupedCard(
          children: [
            for (final offer in state.offers)
              RadioListTile<String>(
                value: offer.id,
                enabled: !state.busy,
                title: Text(_periodTitle(offer)),
                subtitle: Text(_priceLine(offer)),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: state.busy ? null : () => _purchase(selected),
        child: state.busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                selected.trialDays == null
                    ? 'Subscribe'
                    : 'Start ${selected.trialDays}-day free trial',
              ),
      ),
      const SizedBox(height: 10),
      Center(
        child: TextButton(
          onPressed: state.busy ? null : _restore,
          child: const Text('Restore purchases'),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Auto-renews until cancelled. Cancel any time in your $store '
        'settings.',
        textAlign: TextAlign.center,
        style: textTheme.bodySmall?.copyWith(color: t.textMuted),
      ),
    ];
  }

  static String _periodTitle(BillingOffer offer) =>
      offer.period == BillingPeriod.yearly ? 'Yearly' : 'Monthly';

  /// The store's own price string, never one we build.
  static String _priceLine(BillingOffer offer) {
    final unit = offer.period == BillingPeriod.yearly ? 'year' : 'month';
    final price = '${offer.priceText} / $unit';
    final days = offer.trialDays;
    return days == null ? price : '$days-day free trial, then $price';
  }

  /// Terms and Privacy are a store requirement on the paywall, so they are
  /// always shown: the backend's `/api/appinfo` URLs when it has them, else
  /// the website's `/terms` and `/privacy` pages.
  Widget _legalLinks() {
    final info = ref.watch(appInfoNotifierProvider).value;
    final site = ref.watch(appConfigProvider).websiteBaseUrl;
    final terms =
        info?.termsOfServiceUrl ?? (site == null ? null : '$site/terms');
    final privacy =
        info?.privacyPolicyUrl ?? (site == null ? null : '$site/privacy');
    if (terms == null && privacy == null) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        if (terms != null)
          TextButton(
            onPressed: () => openExternalLink(ref, Uri.parse(terms)),
            child: const Text('Terms of Use'),
          ),
        if (privacy != null)
          TextButton(
            onPressed: () => openExternalLink(ref, Uri.parse(privacy)),
            child: const Text('Privacy Policy'),
          ),
      ],
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _purchase(BillingOffer offer) async {
    final toast = ref.read(toastControllerProvider);
    final outcome = await ref
        .read(paywallNotifierProvider.notifier)
        .purchase(offer);
    if (!mounted) return;
    _report(outcome, toast, success: 'Welcome to Pro');
  }

  Future<void> _restore() async {
    final toast = ref.read(toastControllerProvider);
    final outcome = await ref.read(paywallNotifierProvider.notifier).restore();
    if (!mounted) return;
    _report(outcome, toast, success: 'Purchases restored');
  }

  void _report(
    PaywallOutcome outcome,
    ToastController toast, {
    required String success,
  }) {
    switch (outcome) {
      case PaywallPurchased() || PaywallRestored():
        toast.show(
          type: ToastType.success,
          title: success,
          message: 'JobTrigger Pro is active.',
        );
        _close();
      case PaywallNothingToRestore():
        toast.show(
          type: ToastType.info,
          title: 'Nothing to restore',
          message: 'This store account has no active JobTrigger Pro.',
        );
      case PaywallCancelled():
        // The user closed the store sheet: say nothing.
        break;
      case PaywallFailed(:final failure):
        toast.show(
          type: ToastType.error,
          title: "That didn't go through",
          message: failure.message,
        );
    }
  }
}
