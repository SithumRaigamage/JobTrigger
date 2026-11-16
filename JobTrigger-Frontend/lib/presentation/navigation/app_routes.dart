/// Route paths for every screen in the feature matrix
/// (`docs/migration-strategy.md §3`). Split out from `app_router.dart` so
/// screens can reference paths (e.g. for `context.go`) without importing
/// the router itself.
abstract class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
  static const signup = '/signup';
  static const toolSelection = '/tools';
  static const home = '/home';
  static const jobDetail = '/home/job';
  static const buildLog = '/home/job/build-log';
  static const buildDetail = '/home/job/build';
  static const jobHistory = '/home/job/history';
  static const queue = '/home/queue';

  /// NR-02: the unified dashboard across every configured tool.
  static const dashboard = '/dashboard';

  /// NR-03: `jobtrigger://app/pair?url=<server>&name=<label>` — what the
  /// website's pairing QR opens.
  static const pair = '/pair';
  static const nodes = '/home/nodes';

  /// US-JX-19: `jobtrigger://app/open?url=<Jenkins URL>` lands here.
  static const openLink = '/open';
  static const globalHistory = '/history';
  static const sonarqubeProject = '/sonarqube/project';
  static const sonarqubeIssue = '/sonarqube/project/issues/detail';
  static const sonarqubeAnalyses = '/sonarqube/project/analyses';
  static const sonarqubeIssues = '/sonarqube/project/issues';

  /// US-SQ-SERVER-01: the server's version and status.
  static const sonarqubeServer = '/sonarqube/server';

  /// US-SQ-QUALITY-12: a project's worst files for a measure.
  static const sonarqubeWorstFiles = '/sonarqube/project/worst-files';

  /// US-SQ-QUALITY-11: a measure's history for a project.
  static const sonarqubeTrends = '/sonarqube/project/trends';

  /// US-SQ-HOTSPOT-01: a project's security hotspots.
  static const sonarqubeHotspots = '/sonarqube/project/hotspots';

  /// US-SQ-ISSUES-01: the caller's open issues across every project.
  static const sonarqubeMyIssues = '/sonarqube/my-issues';
  static const githubWorkflows = '/github/repos/workflows';
  static const githubRuns = '/github/repos/workflows/runs';
  static const githubGlobalHistory = '/github/history';
  static const githubHistory = '/github/repos/workflows/history';
  static const githubRunDetail = '/github/repos/workflows/runs/detail';
  static const githubJobLog = '/github/repos/workflows/runs/detail/log';
  // Add/edit server is a modal bottom sheet (ServerEditBottomSheet), not a
  // route — see presentation/features/settings/server_edit_bottom_sheet.dart.
  static const settings = '/settings';
  static const profile = '/profile';
  static const appInfo = '/profile/app-info';

  /// Phase 20: both reachable only when billing is available
  /// (`billingAvailableProvider`); otherwise they go to Home.
  static const subscription = '/profile/subscription';
  static const paywall = '/paywall';

  /// Phase 21: also billing-only; opened from the Subscription screen.
  static const studentVerification = '/profile/subscription/student';
}
