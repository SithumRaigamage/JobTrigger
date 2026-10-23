import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

enum AppEnvironment { dev, staging, prod }

/// The local `JobTrigger-Backend` that a debug run without
/// `--dart-define-from-file` talks to.
const _devBackendBaseUrl = 'http://127.0.0.1:5001';

/// Typed view over the `--dart-define-from-file=config/<env>.json` values —
/// see `config/README.md`. Nothing in the app should read
/// `String.fromEnvironment` directly outside this file.
class AppConfig {
  const AppConfig({required this.environment, required this.backendBaseUrl});

  /// AUD-43: a release build without its config used to fall back to the
  /// dev backend (`http://127.0.0.1:5001`) and fail silently at the first
  /// login. Now it throws a [StateError] naming the problem, and
  /// `main()` builds the config before `runApp`, so the app fails at
  /// launch instead. Debug and profile builds keep the dev fallback.
  factory AppConfig.fromEnvironment({bool isRelease = kReleaseMode}) {
    const environmentName = String.fromEnvironment('ENVIRONMENT');
    const backendBaseUrl = String.fromEnvironment('BACKEND_BASE_URL');
    if (isRelease) {
      final problem = releaseConfigProblem(
        environmentName: environmentName,
        backendBaseUrl: backendBaseUrl,
      );
      if (problem != null) throw StateError(problem);
    }
    return AppConfig(
      environment: AppEnvironment.values.firstWhere(
        (candidate) => candidate.name == environmentName,
        orElse: () => AppEnvironment.dev,
      ),
      backendBaseUrl: backendBaseUrl.isEmpty
          ? _devBackendBaseUrl
          : backendBaseUrl,
    );
  }

  final AppEnvironment environment;
  final String backendBaseUrl;

  /// Jenkins versions older than this get an informational "consider
  /// upgrading" note in Settings (US-JX-18). Roughly a year of LTS lines
  /// back from the one the app is verified against (2.568.3). Bump it
  /// alongside the fixture's pinned version.
  static const recommendedJenkinsBaseline = '2.516.1';
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
