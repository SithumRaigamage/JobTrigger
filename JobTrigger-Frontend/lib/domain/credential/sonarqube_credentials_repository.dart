import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'sonarqube_credential.dart';

/// Mirrors `GitHubCredentialsRepository`'s shape for SonarQube credentials
/// — see that interface's doc comment for why `add`/`update` take fields
/// directly rather than a `SonarQubeCredential`.
abstract class SonarQubeCredentialsRepository {
  Future<Result<List<SonarQubeCredential>, AppFailure>> fetchAll();

  Future<Result<SonarQubeCredential, AppFailure>> add({
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    bool isDefault = false,
  });

  Future<Result<SonarQubeCredential, AppFailure>> update(
    String id, {
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    bool isDefault = false,
  });

  Future<Result<void, AppFailure>> delete(String id);

  Future<Result<SonarQubeCredential, AppFailure>> switchActive(String id);
}
