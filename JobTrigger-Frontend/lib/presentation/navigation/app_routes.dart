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
  static const jobHistory = '/home/job/history';
  static const globalHistory = '/history';
  // Add/edit server is a modal bottom sheet (ServerEditBottomSheet), not a
  // route — see presentation/features/settings/server_edit_bottom_sheet.dart.
  static const settings = '/settings';
  static const profile = '/profile';
  static const appInfo = '/profile/app-info';
}
