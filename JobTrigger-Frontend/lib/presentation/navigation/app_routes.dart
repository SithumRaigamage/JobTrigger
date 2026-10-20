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
  static const nodes = '/home/nodes';

  /// US-JX-19: `jobtrigger://app/open?url=<Jenkins URL>` lands here.
  static const openLink = '/open';
  static const globalHistory = '/history';
  static const githubWorkflows = '/github/repos/workflows';
  // Add/edit server is a modal bottom sheet (ServerEditBottomSheet), not a
  // route — see presentation/features/settings/server_edit_bottom_sheet.dart.
  static const settings = '/settings';
  static const profile = '/profile';
  static const appInfo = '/profile/app-info';
}
