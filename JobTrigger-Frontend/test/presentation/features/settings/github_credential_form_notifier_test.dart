import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/github_credentials_repository.dart';
import 'package:job_trigger/presentation/features/settings/active_github_credential_notifier.dart';
import 'package:job_trigger/presentation/features/settings/github_credential_form_notifier.dart';
import 'package:job_trigger/presentation/features/settings/github_credentials_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _FakeGitHubCredentialsRepository implements GitHubCredentialsRepository {
  _FakeGitHubCredentialsRepository(this._credentials);

  final List<GitHubCredential> _credentials;
  Result<GitHubCredential, AppFailure>? addResult;
  Result<GitHubCredential, AppFailure>? updateResult;
  String? lastUpdatedId;

  @override
  Future<Result<List<GitHubCredential>, AppFailure>> fetchAll() async =>
      Ok(List.of(_credentials));

  @override
  Future<Result<GitHubCredential, AppFailure>> add({
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  }) async {
    final result = addResult!;
    if (result case Ok(:final value)) _credentials.add(value);
    return result;
  }

  @override
  Future<Result<GitHubCredential, AppFailure>> update(
    String id, {
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  }) async {
    lastUpdatedId = id;
    return updateResult!;
  }

  @override
  Future<Result<void, AppFailure>> delete(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<GitHubCredential, AppFailure>> switchActive(String id) =>
      throw UnimplementedError();
}

GitHubCredential _credential(String id, {bool isDefault = false}) =>
    GitHubCredential(
      id: id,
      label: 'Credential $id',
      secret: 'ghp_$id',
      isDefault: isDefault,
    );

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test(
    'adding a credential refreshes the credentials list on success',
    () async {
      final repo = _FakeGitHubCredentialsRepository([])
        ..addResult = Ok(_credential('a'));
      final container = ProviderContainer(
        overrides: [
          gitHubCredentialsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(gitHubCredentialFormNotifierProvider, (_, _) {});
      container.listen(gitHubCredentialsNotifierProvider, (_, _) {});

      await container
          .read(gitHubCredentialFormNotifierProvider.notifier)
          .save(label: 'Credential a', secret: 'ghp_a', isDefault: false);

      expect(
        container.read(gitHubCredentialFormNotifierProvider).hasError,
        isFalse,
      );
      final credentials = await container.read(
        gitHubCredentialsNotifierProvider.future,
      );
      expect(credentials.map((credential) => credential.id), ['a']);
    },
  );

  test(
    'editing a credential calls repository.update with the given id',
    () async {
      final existing = _credential('a');
      final repo = _FakeGitHubCredentialsRepository([existing])
        ..updateResult = Ok(_credential('a'));
      final container = ProviderContainer(
        overrides: [
          gitHubCredentialsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(gitHubCredentialFormNotifierProvider, (_, _) {});
      container.listen(gitHubCredentialsNotifierProvider, (_, _) {});

      await container
          .read(gitHubCredentialFormNotifierProvider.notifier)
          .save(id: 'a', label: 'Renamed', secret: 'ghp_a', isDefault: false);

      expect(repo.lastUpdatedId, 'a');
      expect(
        container.read(gitHubCredentialFormNotifierProvider).hasError,
        isFalse,
      );
    },
  );

  test(
    'saving with isDefault: true sets the new credential as the active one',
    () async {
      // Regression test: mirrors ServerFormNotifier's fix for the same
      // gap -- saving with the default toggle on should mean "use this
      // one now," not just flag it and hope a future rehydrate picks it
      // up.
      final saved = _credential('a', isDefault: true);
      final repo = _FakeGitHubCredentialsRepository([])
        ..addResult = Ok(saved);
      final container = ProviderContainer(
        overrides: [
          gitHubCredentialsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(gitHubCredentialFormNotifierProvider, (_, _) {});
      container.listen(gitHubCredentialsNotifierProvider, (_, _) {});
      container.listen(activeGitHubCredentialNotifierProvider, (_, _) {});

      await container
          .read(gitHubCredentialFormNotifierProvider.notifier)
          .save(label: 'Credential a', secret: 'ghp_a', isDefault: true);

      expect(
        container.read(activeGitHubCredentialNotifierProvider)?.id,
        'a',
      );
    },
  );

  test(
    'a repository failure surfaces as GitHubCredentialFormNotifier state error',
    () async {
      final repo = _FakeGitHubCredentialsRepository([])
        ..addResult = const Err(ServerFailure(500));
      final container = ProviderContainer(
        overrides: [
          gitHubCredentialsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(gitHubCredentialFormNotifierProvider, (_, _) {});

      await container
          .read(gitHubCredentialFormNotifierProvider.notifier)
          .save(label: 'Credential a', secret: 'ghp_a', isDefault: false);

      expect(
        container.read(gitHubCredentialFormNotifierProvider).error,
        isA<AppFailure>(),
      );
    },
  );
}
