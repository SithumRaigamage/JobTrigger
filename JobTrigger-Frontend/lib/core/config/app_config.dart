import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

enum AppEnvironment { dev, staging, prod }

/// The local `JobTrigger-Backend` that a debug run without
/// `--dart-define-from-file` talks to.
const _devBackendBaseUrl = 'http://127.0.0.1:5001';

/// The local `JobTrigger-Web` (`npm run dev`) for the same kind of run.
const _devWebsiteBaseUrl = 'http://localhost:3000';

/// Typed view over the `--dart-define-from-file=config/<env>.json` values —
/// see `config/README.md`. Nothing in the app should read
/// `String.fromEnvironment` directly outside this file.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.backendBaseUrl,
    this.websiteBaseUrl,
  });

  /// AUD-43: a release build without its config used to fall back to the
  /// dev backend (`http://127.0.0.1:5001`) and fail silently at the first
  /// login. Now it throws a [StateError] naming the problem, and
  /// `main()` builds the config before `runApp`, so the app fails at
  /// launch instead. Debug and profile builds keep the dev fallback.
  factory AppConfig.fromEnvironment({bool isRelease = kReleaseMode}) {
    const environmentName = String.fromEnvironment('ENVIRONMENT');
    const backendBaseUrl = String.fromEnvironment('BACKEND_BASE_URL');
    const websiteBaseUrl = String.fromEnvironment('WEBSITE_BASE_URL');
    if (isRelease) {
      final problem = releaseConfigProblem(
        environmentName: environmentName,
        backendBaseUrl: backendBaseUrl,
      );
      if (problem != null) throw StateError(problem);
    }
    final environment = AppEnvironment.values.firstWhere(
      (candidate) => candidate.name == environmentName,
      orElse: () => AppEnvironment.dev,
    );
    return AppConfig(
      environment: environment,
      backendBaseUrl: backendBaseUrl.isEmpty
          ? _devBackendBaseUrl
          : backendBaseUrl,
      websiteBaseUrl: websiteBaseUrlFor(environment, websiteBaseUrl),
    );
  }

  final AppEnvironment environment;
  final String backendBaseUrl;

  /// The JobTrigger website (`JobTrigger-Web`), where a forgotten password
  /// is reset (US-AUTH-08: reset happens on the web only, not in the app).
  /// Null when a non-dev build has none configured; the login screen then
  /// hides its "Forgot password?" link rather than open a wrong address.
  final String? websiteBaseUrl;

  /// The website's reset page, or null (see [websiteBaseUrl]).
  Uri? get forgotPasswordUri => websiteBaseUrl == null
      ? null
      : Uri.parse('$websiteBaseUrl/forgot-password');

  /// Jenkins versions older than this get an informational "consider
  /// upgrading" note in Settings (US-JX-18). Roughly a year of LTS lines
  /// back from the one the app is verified against (2.568.3). Bump it
  /// alongside the fixture's pinned version.
  static const recommendedJenkinsBaseline = '2.516.1';
}

/// [configured] without a trailing slash; the local site for a dev run
/// that sets nothing; otherwise null.
@visibleForTesting
String? websiteBaseUrlFor(AppEnvironment environment, String configured) {
  final trimmed = configured.trim().replaceAll(RegExp(r'/+$'), '');
  if (trimmed.isNotEmpty) return trimmed;
  return environment == AppEnvironment.dev ? _devWebsiteBaseUrl : null;
}

/// Why a release build's config is unusable, or null (AUD-43): it must name
/// a non-dev environment and an `https://` backend, since the backend
/// receives account passwords and JWTs.
@visibleForTesting
String? releaseConfigProblem({
  required String environmentName,
  required String backendBaseUrl,
}) {
  const hint = 'Build with --dart-define-from-file=config/prod.json.';
  if (environmentName.isEmpty || backendBaseUrl.isEmpty) {
    return 'This release build has no backend configuration. $hint';
  }
  if (environmentName == AppEnvironment.dev.name) {
    return 'This release build uses the dev configuration. $hint';
  }
  final uri = Uri.tryParse(backendBaseUrl);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    return 'BACKEND_BASE_URL must be an https:// URL in a release build.';
  }
  return null;
}

@riverpod
AppConfig appConfig(Ref ref) => AppConfig.fromEnvironment();
