import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/subscription/entitlements.dart';
import '../../../domain/subscription/subscription_status.dart';
import '../../common_widgets/external_link.dart';
import '../../common_widgets/grouped_card.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/toast_controller.dart';
import '../../navigation/app_routes.dart';
import 'entitlements_notifier.dart';
import 'paywall_notifier.dart';
import 'store_links.dart';

/// P20-24 / US-SUB-01: Profile → Subscription. The plan, when it renews or
/// ends and where it was bought, with the way to manage it where it was
/// bought. A store subscription links to the store's own page; a web
/// subscription (P20-84) is shown as Pro with plain text and **no link**,
/// since the app never points iOS users at web checkout. Reachable only
/// when `billingAvailableProvider` is true.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(entitlementsNotifierProvider).value;
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ResponsiveCenter(
                child: snapshot == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              'Subscription',
                              style: textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GroupedCard(
                            children: [
                              ListTile(
                                title: const Text('Plan'),
                                trailing: Text(
                                  snapshot.entitlements.isPro
                                      ? 'JobTrigger Pro'
                                      : 'Free',
                                ),
                              ),
                              if (_dateRow(snapshot) case final row?)
                                ListTile(
                                  title: Text(row.$1),
                                  trailing: Text(row.$2),
                                ),
                              if (_sourceNote(snapshot) case final note?)
                                ListTile(
                                  title: Text(note),
                                  titleTextStyle: textTheme.bodySmall?.copyWith(
                                    color: t.textMuted,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._actions(context, ref, snapshot),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Renews on" / "Ends on" with the date, or null when there is none.
  (String, String)? _dateRow(SubscriptionSnapshot snapshot) {
    final end = snapshot.status.periodEnd;
    if (end == null || !snapshot.entitlements.isPro) return null;
    final label = snapshot.status.willRenew ? 'Renews on' : 'Ends on';
    return (label, _formatDate(end.toLocal()));
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];

  static String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// Where it was bought, and where it is managed.
  String? _sourceNote(SubscriptionSnapshot snapshot) {
    if (!snapshot.entitlements.isPro) return null;
    final status = snapshot.status;
    if (status.isStore) {
      return 'Bought in the ${storeNameOf(status.source)}. Manage or cancel '
          'it there.';
    }
    if (status.isWeb) {
      return 'Bought on the JobTrigger website, and managed there.';
    }
    if (status.source != null) return 'Included with your account.';
    return null;
  }

  List<Widget> _actions(
    BuildContext context,
    WidgetRef ref,
    SubscriptionSnapshot snapshot,
  ) {
    final status = snapshot.status;
    if (!snapshot.entitlements.isPro) {
      return [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => context.push(AppRoutes.paywall),
          child: const Text('Upgrade to Pro'),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => _restore(context, ref),
            child: const Text('Restore purchases'),
          ),
        ),
      ];
    }
    if (status.isStore) {
      return [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: () => openExternalLink(
            ref,
            manageSubscriptionUri(
              status.source == SubscriptionSource.appStore
                  ? TargetPlatform.iOS
                  : TargetPlatform.android,
            ),
          ),
          child: Text('Manage in the ${storeNameOf(status.source)}'),
        ),
      ];
    }
    // Web, promo and admin Pro: nothing to buy and nothing to link to.
    return const [];
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final toast = ref.read(toastControllerProvider);
    final outcome = await ref.read(paywallNotifierProvider.notifier).restore();
    switch (outcome) {
      case PaywallRestored():
        toast.show(
          type: ToastType.success,
          title: 'Purchases restored',
          message: 'JobTrigger Pro is active.',
        );
      case PaywallNothingToRestore():
        toast.show(
          type: ToastType.info,
          title: 'Nothing to restore',
          message: 'This store account has no active JobTrigger Pro.',
        );
      case PaywallCancelled() || PaywallPurchased():
        break;
      case PaywallFailed(:final failure):
        toast.show(
          type: ToastType.error,
          title: "Couldn't restore",
          message: failure.message,
        );
    }
  }
}

/// The Profile row's value: "Pro" or "Free".
String planLabel(Entitlements entitlements) =>
    entitlements.isPro ? 'Pro' : 'Free';
