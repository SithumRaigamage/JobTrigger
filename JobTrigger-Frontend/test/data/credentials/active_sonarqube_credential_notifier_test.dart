import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/sonarqube_credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/credential/sonarqube_credentials_repository.dart';
import 'package:job_trigger/presentation/features/settings/active_sonarqube_credential_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// In-memory fake, mirrors `active_github_credential_notifier_test.dart`'s
/// `_FakeGitHubCredentialsRepository` exactly.
class _FakeSonarQubeCredentialsRepository
    implements SonarQubeCredentialsRepository {
  _FakeSonarQubeCredentialsRepository(this._credentials);

  final List<SonarQubeCredential> _credentials;

  @override
  Future<Result<List<SonarQubeCredential>, AppFailure>> fetchAll() async =>
      Ok(List.of(_credentials));

  @override
  Future<Result<void, AppFailure>> delete(String id) async {
    _credentials.removeWhere((credential) => credential.id == id);
    return const Ok(null);
  }

  @override
  Future<Result<SonarQubeCredential, AppFailure>> add({
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    bool isDefault = false,
  }) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeCredential, AppFailure>> update(
    String id, {
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    bool isDefault = false,
  }) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeCredential, AppFailure>> switchActive(String id) =>
      throw UnimplementedError();
}

SonarQubeCredential _credential(String id, {bool isDefault = false}) =>
    SonarQubeCredential(
      id: id,
      label: 'Credential $id',
      baseUrl: 'https://sonarcloud.io',
      secret: 'squ_$id',
      isDefault: isDefault,
    );

ProviderContainer _containerWith(List<SonarQubeCredential> credentials) {
  final repo = _FakeSonarQubeCredentialsRepository(credentials);
  return ProviderContainer(
    overrides: [sonarQubeCredentialsRepositoryProvider.overrideWithValue(repo)],
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
        activeSonarQubeCredentialNotifierProvider.notifier,
      );
      await notifier.setActiveCredential(credentialA);

      final result = await notifier.deleteCredential(credentialA);

      expect(result, isA<Ok<void, AppFailure>>());
      expect(
        container.read(activeSonarQubeCredentialNotifierProvider)?.id,
        'b',
      );
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
        activeSonarQubeCredentialNotifierProvider.notifier,
      );
      await notifier.setActiveCredential(credentialA);

      await notifier.deleteCredential(credentialA);

      expect(
        container.read(activeSonarQubeCredentialNotifierProvider)?.id,
        'b',
      );
    },
  );

  test('deleting the only credential clears the active credential', () async {
    final credentialA = _credential('a');
    final container = _containerWith([credentialA]);
    addTearDown(container.dispose);

    final notifier = container.read(
      activeSonarQubeCredentialNotifierProvider.notifier,
    );
    await notifier.setActiveCredential(credentialA);

    await notifier.deleteCredential(credentialA);

    expect(container.read(activeSonarQubeCredentialNotifierProvider), isNull);
  });

  test(
    'deleting a non-active credential leaves the active credential untouched',
    () async {
      final credentialA = _credential('a');
      final credentialB = _credential('b');
      final container = _containerWith([credentialA, credentialB]);
      addTearDown(container.dispose);

      final notifier = container.read(
        activeSonarQubeCredentialNotifierProvider.notifier,
      );
      await notifier.setActiveCredential(credentialA);

      await notifier.deleteCredential(credentialB);

      expect(
        container.read(activeSonarQubeCredentialNotifierProvider)?.id,
        'a',
      );
    },
  );
}
