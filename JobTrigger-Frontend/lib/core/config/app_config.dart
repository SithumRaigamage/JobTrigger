import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

enum AppEnvironment { dev, staging, prod }

/// Typed view over the `--dart-define-from-file=config/<env>.json` values —
/// see `config/README.md`. Nothing in the app should read
/// `String.fromEnvironment` directly outside this file.
class AppConfig {
  const AppConfig({required this.environment, required this.backendBaseUrl});

  factory AppConfig.fromEnvironment() {
    const environmentName = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'dev',
    );
    const backendBaseUrl = String.fromEnvironment(
      'BACKEND_BASE_URL',
      defaultValue: 'http://127.0.0.1:5001',
    );
    return AppConfig(
      environment: AppEnvironment.values.firstWhere(
        (candidate) => candidate.name == environmentName,
        orElse: () => AppEnvironment.dev,
      ),
      backendBaseUrl: backendBaseUrl,
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

@riverpod
AppConfig appConfig(Ref ref) => AppConfig.fromEnvironment();
