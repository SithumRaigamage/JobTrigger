import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'github_credential.dart';

/// Mirrors `CredentialsRepository`'s shape for GitHub credentials — see
/// that interface's doc comment for why `add`/`update` take fields
/// directly rather than a `GitHubCredential`.
abstract class GitHubCredentialsRepository {
  Future<Result<List<GitHubCredential>, AppFailure>> fetchAll();

  Future<Result<GitHubCredential, AppFailure>> add({
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  });

  Future<Result<GitHubCredential, AppFailure>> update(
    String id, {
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  });

  Future<Result<void, AppFailure>> delete(String id);

  Future<Result<GitHubCredential, AppFailure>> switchActive(String id);
}
