import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/github_credentials_repository.dart';
import 'package:job_trigger/presentation/features/settings/active_github_credential_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// In-memory fake, mirrors `active_server_notifier_test.dart`'s
/// `_FakeCredentialsRepository` exactly.
class _FakeGitHubCredentialsRepository implements GitHubCredentialsRepository {
  _FakeGitHubCredentialsRepository(this._credentials);

  final List<GitHubCredential> _credentials;

  @override
  Future<Result<List<GitHubCredential>, AppFailure>> fetchAll() async =>
      Ok(List.of(_credentials));

  @override
  Future<Result<void, AppFailure>> delete(String id) async {
    _credentials.removeWhere((credential) => credential.id == id);
    return const Ok(null);
  }

  @override
  Future<Result<GitHubCredential, AppFailure>> add({
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  }) => throw UnimplementedError();

  @override
  Future<Result<GitHubCredential, AppFailure>> update(
    String id, {
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  }) => throw UnimplementedError();

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

ProviderContainer _containerWith(List<GitHubCredential> credentials) {
  final repo = _FakeGitHubCredentialsRepository(credentials);
  return ProviderContainer(
    overrides: [gitHubCredentialsRepositoryProvider.overrideWithValue(repo)],
  );
}

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test(
    'deleting the active credential falls back to the remaining isDefault credential',
    () async {
      final credentialA = _credential('a');
      final credentialB = _credential('b', isDefault: true);
      final container = _containerWith([credentialA, credentialB]);
      addTearDown(container.dispose);

      final notifier = container.read(
        activeGitHubCredentialNotifierProvider.notifier,
      );
      await notifier.setActiveCredential(credentialA);

      final result = await notifier.deleteCredential(credentialA);

      expect(result, isA<Ok<void, AppFailure>>());
      expect(container.read(activeGitHubCredentialNotifierProvider)?.id, 'b');
    },
  );

  test(
    'deleting the active credential falls back to the first remaining credential when none is default',
    () async {
      final credentialA = _credential('a');
      final credentialB = _credential('b');
      final container = _containerWith([credentialA, credentialB]);
      addTearDown(container.dispose);

      final notifier = container.read(
        activeGitHubCredentialNotifierProvider.notifier,
      );
      await notifier.setActiveCredential(credentialA);

      await notifier.deleteCredential(credentialA);

      expect(container.read(activeGitHubCredentialNotifierProvider)?.id, 'b');
    },
  );

  test('deleting the only credential clears the active credential', () async {
    final credentialA = _credential('a');
    final container = _containerWith([credentialA]);
    addTearDown(container.dispose);

    final notifier = container.read(
      activeGitHubCredentialNotifierProvider.notifier,
    );
    await notifier.setActiveCredential(credentialA);

    await notifier.deleteCredential(credentialA);

    expect(container.read(activeGitHubCredentialNotifierProvider), isNull);
  });

  test(
    'deleting a non-active credential leaves the active credential untouched',
    () async {
      final credentialA = _credential('a');
      final credentialB = _credential('b');
      final container = _containerWith([credentialA, credentialB]);
      addTearDown(container.dispose);

      final notifier = container.read(
        activeGitHubCredentialNotifierProvider.notifier,
      );
      await notifier.setActiveCredential(credentialA);

      await notifier.deleteCredential(credentialB);

      expect(container.read(activeGitHubCredentialNotifierProvider)?.id, 'a');
    },
  );
}
