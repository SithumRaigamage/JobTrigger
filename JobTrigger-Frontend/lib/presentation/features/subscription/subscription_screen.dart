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
import '../student/student_expiry_notice.dart';
import 'billing_availability.dart';
import 'entitlements_notifier.dart';
import 'paywall_notifier.dart';
import 'promo_code_dialog.dart';
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
    final sandbox = ref.watch(sandboxBillingProvider);
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
                          const StudentExpiryBanner(),
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
                          // Development only: a release build has no sandbox
                          // client, so this card never renders.
                          if (sandbox != null) ...[
                            const SizedBox(height: 16),
                            GroupedCard(
                              children: [
                                const ListTile(
                                  leading: Icon(Icons.science_outlined),
                                  title: Text('Sandbox billing'),
                                  subtitle: Text(
                                    'No payment is taken. These controls '
                                    'exist only on a development build.',
                                  ),
                                ),
                                if (snapshot.entitlements.isPro &&
                                    snapshot.status.willRenew)
                                  ListTile(
                                    key: const Key('sandbox_cancel'),
                                    leading: const Icon(Icons.cancel_outlined),
                                    title: const Text('Cancel subscription'),
                                    subtitle: const Text(
                                      'Pro stays until the period ends.',
                                    ),
                                    onTap: () => _sandboxAction(
                                      ref,
                                      sandbox.cancelSubscription,
                                      'Subscription cancelled',
                                    ),
                                  ),
                                if (snapshot.entitlements.isPro &&
                                    !snapshot.status.willRenew)
                                  ListTile(
                                    key: const Key('sandbox_resubscribe'),
                                    leading: const Icon(
                                      Icons.autorenew_rounded,
                                    ),
                                    title: const Text('Resubscribe'),
                                    onTap: () => _sandboxAction(
                                      ref,
                                      sandbox.resubscribe,
                                      'Subscription resumed',
                                    ),
                                  ),
                                if (snapshot.entitlements.isPro)
                                  ListTile(
                                    key: const Key('sandbox_expire'),
                                    leading: const Icon(
                                      Icons.hourglass_bottom_rounded,
                                    ),
                                    title: const Text('Simulate expiry'),
                                    subtitle: const Text(
                                      "End the period now to see Free's limits.",
                                    ),
                                    onTap: () => _sandboxAction(
                                      ref,
                                      sandbox.expireNow,
                                      'Subscription expired',
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          // Phase 21: the free student year. Free users can
                          // start it; a student sees where it stands.
                          if (!snapshot.entitlements.isPro ||
                              snapshot.status.isStudent) ...[
                            const SizedBox(height: 16),
                            GroupedCard(
                              children: [
                                ListTile(
                                  key: const Key('student_entry'),
                                  leading: const Icon(Icons.school_outlined),
                                  title: Text(
                                    snapshot.status.isStudent
                                        ? 'Student status'
                                        : 'Verify student status',
                                  ),
                                  subtitle: snapshot.status.isStudent
                                      ? null
                                      : const Text(
                                          'Students get Pro free for one '
                                          'year.',
                                        ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () => context.push(
                                    AppRoutes.studentVerification,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // US-PROMO-01: only when the backend has codes, and
                          // only while Free (a code adds nothing to Pro).
                          if (snapshot.promoAvailable &&
                              !snapshot.entitlements.isPro) ...[
                            const SizedBox(height: 16),
                            GroupedCard(
                              children: [
                                ListTile(
                                  key: const Key('promo_entry'),
                                  leading: const Icon(
                                    Icons.confirmation_number_outlined,
                                  ),
                                  title: const Text('Redeem a code'),
                                  subtitle: const Text(
                                    'Have a promo or voucher code?',
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () => _redeemCode(context, ref),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Renews on" / "Ends on" / "Trial ends" with the date, or null.
  (String, String)? _dateRow(SubscriptionSnapshot snapshot) {
    final end = snapshot.status.periodEnd;
    if (end == null || !snapshot.entitlements.isPro) return null;
    final label = switch (snapshot.status.state) {
      SubscriptionState.trialing => 'Trial ends',
      // The end date is what the user cares about once a charge failed.
      SubscriptionState.billingIssue || SubscriptionState.grace => 'Pro until',
      _ => snapshot.status.willRenew ? 'Renews on' : 'Ends on',
    };
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
    final status = snapshot.status;
    if (!snapshot.entitlements.isPro) {
      return status.state == SubscriptionState.expired
          ? 'Your Pro plan has ended. Nothing you saved was deleted.'
          : null;
    }
    if (status.isStore) {
      if (status.state == SubscriptionState.billingIssue ||
          status.state == SubscriptionState.grace) {
        return 'The last payment didn\'t go through. Update your payment '
            'method in the ${storeNameOf(status.source)} before Pro ends.';
      }
      return 'Bought in the ${storeNameOf(status.source)}. Manage or cancel '
          'it there.';
    }
    if (status.isWeb) {
      return 'Bought on the JobTrigger website, and managed there.';
    }
    if (status.isStudent) {
      return 'Free for one year as a verified student.';
    }
    if (status.isPromo) {
      return 'Redeemed with a code.';
    }
    // US-SUB-11 AC16: no purchase, and no link to the website checkout.
    if (status.isTeam) {
      final name = status.team?.name ?? 'your team';
      return status.team?.isOwner ?? false
          ? 'Pro through $name. You manage the team on the JobTrigger '
                'website.'
          : "Pro through $name. Your team's owner manages this plan.";
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
        // A cancelled subscription keeps Pro until the period ends; the
        // store allows buying again before then, so offer it here.
        if (status.state == SubscriptionState.cancelled) ...[
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => context.push(AppRoutes.paywall),
            child: const Text('Resubscribe'),
          ),
        ],
      ];
    }
    // Web, promo and admin Pro: nothing to buy and nothing to link to.
    return const [];
  }

  /// US-PROMO-01: asks for a code, then shows the plan the backend granted.
  /// A refusal never closes the dialog (see [PromoCodeDialog]).
  Future<void> _redeemCode(BuildContext context, WidgetRef ref) async {
    final toast = ref.read(toastControllerProvider);
    final redeemed = await showDialog<bool>(
      context: context,
      builder: (context) => const PromoCodeDialog(),
    );
    if (redeemed != true) return;
    final end = ref.read(entitlementsNotifierProvider).value?.status.periodEnd;
    toast.show(
      type: ToastType.success,
      title: 'Pro is active',
      message: end == null
          ? 'Your code was accepted.'
          : 'Your code was accepted. Pro ends on '
                '${_formatDate(end.toLocal())}.',
    );
  }

  /// Runs one sandbox store action, then re-reads the plan from the
  /// backend. No money moves and nothing is shown as a real purchase.
  Future<void> _sandboxAction(
    WidgetRef ref,
    Future<void> Function() action,
    String title,
  ) async {
    final toast = ref.read(toastControllerProvider);
    try {
      await action();
      await ref.read(entitlementsNotifierProvider.notifier).refresh();
      toast.show(
        type: ToastType.success,
        title: title,
        message: 'Sandbox only: no payment was taken.',
      );
    } on Object {
      toast.show(
        type: ToastType.error,
        title: "That didn't work",
        message: 'The sandbox request failed. Check the backend is running.',
      );
    }
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
      case PaywallCancelled() || PaywallPurchased() || PaywallPending():
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

/// Phase 21: the Profile row's value. "Pro (Student)" for the free student
/// year, otherwise [planLabel].
String planLabelFor(
  Entitlements entitlements,
  SubscriptionSnapshot? snapshot,
) => entitlements.isPro && (snapshot?.status.isStudent ?? false)
    ? 'Pro (Student)'
    : planLabel(entitlements);
