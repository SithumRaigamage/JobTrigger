import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'jenkins_server.dart';

/// `add`/`update` take fields directly rather than a `JenkinsServer` — a new
/// server has no `id` yet (POST body is "Credential minus id" per
/// `docs/api-reference.md`), so there's no valid domain entity to pass for
/// the add case.
abstract class CredentialsRepository {
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll();

  Future<Result<JenkinsServer, AppFailure>> add({
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  });

  Future<Result<JenkinsServer, AppFailure>> update(
    String id, {
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  });

  Future<Result<void, AppFailure>> delete(String id);

  Future<Result<JenkinsServer, AppFailure>> switchActive(String id);
}
