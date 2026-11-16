import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../domain/subscription/entitlements.dart';
import '../../../data/credentials/credentials_notifier.dart';
import '../../../data/credentials/github_credentials_notifier.dart';
import '../../../data/credentials/sonarqube_credentials_notifier.dart';
import '../../navigation/app_routes.dart';
import '../tool_selection/ci_tool.dart';
import 'billing_availability.dart';
import 'entitlements_notifier.dart';

part 'plan_gate.g.dart';

/// P20-25: the one place that decides whether the user's plan allows
/// something. Every method returns the paywall *reason* (the `limit` the
/// backend uses, which `paywallHeadline` understands) when the action is
/// blocked, or null when it is allowed.
///
/// Nothing is ever blocked unless [active] (`billingAvailableProvider`:
/// a purchase key in this build, the backend's `billingEnabled` on, and not
/// demo mode). With billing off every method returns null, so each existing
/// flow behaves exactly as it did before subscriptions.
class PlanGate {
  const PlanGate({required this.active, required this.entitlements});

  /// A gate that never blocks.
  static const open = PlanGate(
    active: false,
    entitlements: Entitlements.unrestricted,
  );

  final bool active;
  final Entitlements entitlements;

  /// Using more than one CI/CD tool.
  String? get multiTool =>
      active && !entitlements.features.multiTool ? 'multiTool' : null;

  /// "Notify me" and the background check.
  String? get backgroundWatch =>
      active && !entitlements.features.backgroundWatch
      ? 'backgroundWatch'
      : null;

  /// The home-screen widget.
  String? get homeWidget =>
      active && !entitlements.features.homeWidget ? 'homeWidget' : null;

  /// Trends, nodes, queue and views.
  String? get insights =>
      active && !entitlements.features.insights ? 'insights' : null;

  /// Pinning one more job when [pinned] are already pinned.
  String? pinJob(int pinned) {
    final limit = entitlements.limits.maxPinnedJobs;
    return active && limit != null && pinned >= limit ? 'maxPinnedJobs' : null;
  }

  /// Saving one more server or account, given how many are saved in all
  /// ([total]) and for the tool being added to ([forTool]).
  String? addCredential({required int total, required int forTool}) {
    if (!active) return null;
    final limits = entitlements.limits;
    final maxTotal = limits.maxCredentialsTotal;
    if (maxTotal != null && total >= maxTotal) return 'maxCredentialsTotal';
    final maxPerTool = limits.maxCredentialsPerTool;
    if (maxPerTool != null && forTool >= maxPerTool) {
      return 'maxCredentialsPerTool';
    }
    return null;
  }

  /// The failure a blocked add-credential becomes, worded like the
  /// backend's own `PLAN_LIMIT` message.
  PlanLimitFailure credentialLimitFailure(String reason) {
    final limits = entitlements.limits;
    final max = reason == 'maxCredentialsPerTool'
        ? limits.maxCredentialsPerTool
        : limits.maxCredentialsTotal;
    final what = max == 1 ? '1 saved server' : '$max saved servers';
    return PlanLimitFailure(
      reason,
      'Your plan allows $what. Upgrade to Pro to add more.',
    );
  }
}

@Riverpod(keepAlive: true)
PlanGate planGate(Ref ref) {
  // Looked at in this order on purpose: with billing off the plan is never
  // read, so a build without purchases makes no `/api/subscription` request
  // just because a gate was checked.
  if (!ref.watch(billingAvailableProvider)) return PlanGate.open;
  return PlanGate(active: true, entitlements: ref.watch(entitlementsProvider));
}

/// How many servers or accounts the user has saved for each tool.
typedef CredentialCounts = ({int jenkins, int github, int sonarqube});

extension CredentialCountsX on CredentialCounts {
  int get total => jenkins + github + sonarqube;

  int of(CiTool tool) => switch (tool) {
    CiTool.jenkins => jenkins,
    CiTool.githubActions => github,
    CiTool.sonarqube => sonarqube,
    _ => 0,
  };
}

/// P20-25: the saved-credential counts for the add-server pre-check. A list
/// that can't be loaded counts as empty: the backend enforces the real
/// limit either way, and this pre-check only saves a round trip.
@riverpod
Future<CredentialCounts> credentialCounts(Ref ref) async {
  Future<int> count<T>(Future<List<T>> list) async {
    try {
      return (await list).length;
    } on Object {
      return 0;
    }
  }

  // All three are started before the first await: this provider can be
  // disposed (nothing listens to it) as soon as the caller has its answer,
  // and `ref` must not be used after that.
  final jenkins = ref.read(credentialsNotifierProvider.future);
  final github = ref.read(gitHubCredentialsNotifierProvider.future);
  final sonarqube = ref.read(sonarQubeCredentialsNotifierProvider.future);
  return (
    jenkins: await count(jenkins),
    github: await count(github),
    sonarqube: await count(sonarqube),
  );
}

/// P20-25: the tools a Free user can't switch to. On a plan without
/// `multiTool`, the user keeps the tool(s) they already saved servers for;
/// every other tool needs Pro. Empty with billing off, or before any
/// server is saved (the first tool is free to choose).
@riverpod
Future<Set<CiTool>> proLockedTools(Ref ref) async {
  if (ref.watch(planGateProvider).multiTool == null) return const {};
  final counts = await ref.watch(credentialCountsProvider.future);
  final tools = CiTool.values.where((tool) => tool.isAvailable);
  if (!tools.any((tool) => counts.of(tool) > 0)) return const {};
  return {
    for (final tool in tools)
      if (counts.of(tool) == 0) tool,
  };
}

/// P20-25: the failure to show instead of saving a new server or account
/// for [tool], or null when the plan allows one more (always null with
/// billing off). Used by the add forms before they call the backend.
Future<PlanLimitFailure?> addCredentialBlock(Ref ref, CiTool tool) async {
  final gate = ref.read(planGateProvider);
  if (!gate.active) return null;
  final counts = await ref.read(credentialCountsProvider.future);
  final reason = gate.addCredential(
    total: counts.total,
    forTool: counts.of(tool),
  );
  return reason == null ? null : gate.credentialLimitFailure(reason);
}

/// The paywall's location for [reason] (`/paywall?reason=<reason>`).
String paywallLocation(String reason) => Uri(
  path: AppRoutes.paywall,
  queryParameters: {'reason': reason},
).toString();

/// Opens the paywall for [reason].
Future<void> openPaywall(BuildContext context, String reason) =>
    context.push(paywallLocation(reason));
