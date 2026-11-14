import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../../domain/app_info/app_info.dart';
import '../../domain/app_info/app_info_repository.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/credential/credentials_repository.dart';
import '../../domain/credential/github_credential.dart';
import '../../domain/credential/github_credentials_repository.dart';
import '../../domain/credential/jenkins_server.dart';
import '../../domain/credential/sonarqube_credential.dart';
import '../../domain/credential/sonarqube_credentials_repository.dart';
import 'demo_data.dart';

/// E2 (PE-10/PE-14): the account side of demo mode. Each lists the one
/// sample credential and refuses every change, so Settings and Profile work
/// as read-only screens and nothing reaches the backend.
const _refused = Err<Never, AppFailure>(DemoUnavailableFailure());

class DemoCredentialsRepository implements CredentialsRepository {
  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      const Ok([demoJenkinsServer]);

  @override
  Future<Result<JenkinsServer, AppFailure>> add({
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) async => _refused;

  @override
  Future<Result<JenkinsServer, AppFailure>> update(
    String id, {
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) async => _refused;

  @override
  Future<Result<void, AppFailure>> delete(String id) async => _refused;

  @override
  Future<Result<JenkinsServer, AppFailure>> switchActive(String id) async =>
      const Ok(demoJenkinsServer);
}

class DemoGitHubCredentialsRepository implements GitHubCredentialsRepository {
  @override
  Future<Result<List<GitHubCredential>, AppFailure>> fetchAll() async =>
      const Ok([demoGitHubCredential]);

  @override
  Future<Result<GitHubCredential, AppFailure>> add({
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  }) async => _refused;

  @override
  Future<Result<GitHubCredential, AppFailure>> update(
    String id, {
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  }) async => _refused;

  @override
  Future<Result<void, AppFailure>> delete(String id) async => _refused;

  @override
  Future<Result<GitHubCredential, AppFailure>> switchActive(String id) async =>
      const Ok(demoGitHubCredential);
}

class DemoSonarQubeCredentialsRepository
    implements SonarQubeCredentialsRepository {
  @override
  Future<Result<List<SonarQubeCredential>, AppFailure>> fetchAll() async =>
      const Ok([demoSonarQubeCredential]);

  @override
  Future<Result<SonarQubeCredential, AppFailure>> add({
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    bool isDefault = false,
  }) async => _refused;

  @override
  Future<Result<SonarQubeCredential, AppFailure>> update(
    String id, {
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    bool isDefault = false,
  }) async => _refused;

  @override
  Future<Result<void, AppFailure>> delete(String id) async => _refused;

  @override
  Future<Result<SonarQubeCredential, AppFailure>> switchActive(
    String id,
  ) async => const Ok(demoSonarQubeCredential);
}

/// The demo has no backend session, so every account action is refused.
class DemoAuthRepository implements AuthRepository {
  @override
  Future<Result<AuthSession, AppFailure>> signup({
    required String email,
    required String password,
  }) async => _refused;

  @override
  Future<Result<AuthSession, AppFailure>> login({
    required String email,
    required String password,
  }) async => _refused;

  @override
  Future<Result<void, AppFailure>> logoutEverywhere() async => _refused;

  @override
  Future<Result<AuthSession, AppFailure>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => _refused;

  @override
  Future<Result<void, AppFailure>> deleteAccount({
    required String password,
  }) async => _refused;
}

/// App info normally comes from the backend; the demo answers locally, with
/// no links (the About screen hides a row with no URL, PE-05).
class DemoAppInfoRepository implements AppInfoRepository {
  @override
  Future<Result<AppInfo, AppFailure>> fetchAppInfo() async =>
      const Ok(AppInfo(appVersion: 'demo', buildNumber: '0'));
}

final demoCredentialsRepository = DemoCredentialsRepository();
final demoGitHubCredentialsRepository = DemoGitHubCredentialsRepository();
final demoSonarQubeCredentialsRepository = DemoSonarQubeCredentialsRepository();
final demoAuthRepository = DemoAuthRepository();
final demoAppInfoRepository = DemoAppInfoRepository();
