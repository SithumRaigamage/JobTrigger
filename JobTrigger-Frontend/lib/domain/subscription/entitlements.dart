/// P20-21: what the signed-in user may do right now. Mirrors
/// `GET /api/subscription` (`docs/api-reference.md`): clients read [limits]
/// and [features], never the plan name, so the backend can change a limit
/// without an app release.
enum Plan { free, pro }

/// `null` means unlimited.
class PlanLimits {
  const PlanLimits({
    required this.maxCredentialsTotal,
    required this.maxCredentialsPerTool,
    required this.maxPinnedJobs,
  });

  final int? maxCredentialsTotal;
  final int? maxCredentialsPerTool;
  final int? maxPinnedJobs;

  static const unlimited = PlanLimits(
    maxCredentialsTotal: null,
    maxCredentialsPerTool: null,
    maxPinnedJobs: null,
  );

  @override
  bool operator ==(Object other) =>
      other is PlanLimits &&
      other.maxCredentialsTotal == maxCredentialsTotal &&
      other.maxCredentialsPerTool == maxCredentialsPerTool &&
      other.maxPinnedJobs == maxPinnedJobs;

  @override
  int get hashCode =>
      Object.hash(maxCredentialsTotal, maxCredentialsPerTool, maxPinnedJobs);
}

class PlanFeatures {
  const PlanFeatures({
    required this.multiTool,
    required this.backgroundWatch,
    required this.homeWidget,
    required this.insights,
  });

  final bool multiTool;
  final bool backgroundWatch;
  final bool homeWidget;
  final bool insights;

  static const all = PlanFeatures(
    multiTool: true,
    backgroundWatch: true,
    homeWidget: true,
    insights: true,
  );

  @override
  bool operator ==(Object other) =>
      other is PlanFeatures &&
      other.multiTool == multiTool &&
      other.backgroundWatch == backgroundWatch &&
      other.homeWidget == homeWidget &&
      other.insights == insights;

  @override
  int get hashCode =>
      Object.hash(multiTool, backgroundWatch, homeWidget, insights);
}

class Entitlements {
  const Entitlements({
    required this.plan,
    required this.billingEnabled,
    required this.limits,
    required this.features,
  });

  /// The value used while nothing is known yet (before the first load, in
  /// demo mode, or when the backend can't be reached and nothing is
  /// cached). It restricts nothing, so a build with billing off, or an
  /// older backend with no `/api/subscription`, behaves exactly as the app
  /// did before subscriptions. The backend enforces the real limits either
  /// way.
  static const unrestricted = Entitlements(
    plan: Plan.pro,
    billingEnabled: false,
    limits: PlanLimits.unlimited,
    features: PlanFeatures.all,
  );

  final Plan plan;

  /// False: the backend treats everyone as Pro and no paywall is shown.
  final bool billingEnabled;
  final PlanLimits limits;
  final PlanFeatures features;

  bool get isPro => plan == Plan.pro;

  @override
  bool operator ==(Object other) =>
      other is Entitlements &&
      other.plan == plan &&
      other.billingEnabled == billingEnabled &&
      other.limits == limits &&
      other.features == features;

  @override
  int get hashCode => Object.hash(plan, billingEnabled, limits, features);
}
