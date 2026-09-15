import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/sonarqube_credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/credential/sonarqube_credentials_repository.dart';
import 'package:job_trigger/presentation/features/settings/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/presentation/features/settings/sonarqube_credential_form_notifier.dart';
import 'package:job_trigger/presentation/features/settings/sonarqube_credentials_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _FakeSonarQubeCredentialsRepository
    implements SonarQubeCredentialsRepository {
  _FakeSonarQubeCredentialsRepository(this._credentials);

  final List<SonarQubeCredential> _credentials;
  Result<SonarQubeCredential, AppFailure>? addResult;
  Result<SonarQubeCredential, AppFailure>? updateResult;
  String? lastUpdatedId;

  @override
  Future<Result<List<SonarQubeCredential>, AppFailure>> fetchAll() async =>
      Ok(List.of(_credentials));

  @override
  Future<Result<SonarQubeCredential, AppFailure>> add({
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    bool isDefault = false,
  }) async {
    final result = addResult!;
    if (result case Ok(:final value)) _credentials.add(value);
    return result;
  }

  @override
  Future<Result<SonarQubeCredential, AppFailure>> update(
    String id, {
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    bool isDefault = false,
  }) async {
    lastUpdatedId = id;
    return updateResult!;
  }

  @override
  Future<Result<void, AppFailure>> delete(String id) =>
      throw UnimplementedError();

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

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test(
    'adding a credential refreshes the credentials list on success',
    () async {
      final repo = _FakeSonarQubeCredentialsRepository([])
        ..addResult = Ok(_credential('a'));
      final container = ProviderContainer(
        overrides: [
          sonarQubeCredentialsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(sonarQubeCredentialFormNotifierProvider, (_, _) {});
      container.listen(sonarQubeCredentialsNotifierProvider, (_, _) {});

      await container
          .read(sonarQubeCredentialFormNotifierProvider.notifier)
          .save(
            label: 'Credential a',
            baseUrl: 'https://sonarcloud.io',
            secret: 'squ_a',
            isDefault: false,
          );

      expect(
        container.read(sonarQubeCredentialFormNotifierProvider).hasError,
        isFalse,
      );
      final credentials = await container.read(
        sonarQubeCredentialsNotifierProvider.future,
      );
      expect(credentials.map((credential) => credential.id), ['a']);
    },
  );

  test(
    'editing a credential calls repository.update with the given id',
    () async {
      final existing = _credential('a');
      final repo = _FakeSonarQubeCredentialsRepository([existing])
        ..updateResult = Ok(_credential('a'));
      final container = ProviderContainer(
        overrides: [
          sonarQubeCredentialsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(sonarQubeCredentialFormNotifierProvider, (_, _) {});
      container.listen(sonarQubeCredentialsNotifierProvider, (_, _) {});

      await container
          .read(sonarQubeCredentialFormNotifierProvider.notifier)
          .save(
            id: 'a',
            label: 'Renamed',
            baseUrl: 'https://sonarcloud.io',
            secret: 'squ_a',
            isDefault: false,
          );

      expect(repo.lastUpdatedId, 'a');
      expect(
        container.read(sonarQubeCredentialFormNotifierProvider).hasError,
        isFalse,
      );
    },
  );

  test(
    'saving with isDefault: true sets the new credential as the active one',
    () async {
      final saved = _credential('a', isDefault: true);
      final repo = _FakeSonarQubeCredentialsRepository([])..addResult = Ok(saved);
      final container = ProviderContainer(
        overrides: [
          sonarQubeCredentialsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(sonarQubeCredentialFormNotifierProvider, (_, _) {});
      container.listen(sonarQubeCredentialsNotifierProvider, (_, _) {});
      container.listen(activeSonarQubeCredentialNotifierProvider, (_, _) {});

      await container
          .read(sonarQubeCredentialFormNotifierProvider.notifier)
          .save(
            label: 'Credential a',
            baseUrl: 'https://sonarcloud.io',
            secret: 'squ_a',
            isDefault: true,
          );

      expect(
        container.read(activeSonarQubeCredentialNotifierProvider)?.id,
        'a',
      );
    },
  );

  test(
    'a repository failure surfaces as SonarQubeCredentialFormNotifier state error',
    () async {
      final repo = _FakeSonarQubeCredentialsRepository([])
        ..addResult = const Err(ServerFailure(500));
      final container = ProviderContainer(
        overrides: [
          sonarQubeCredentialsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(sonarQubeCredentialFormNotifierProvider, (_, _) {});

      await container
          .read(sonarQubeCredentialFormNotifierProvider.notifier)
          .save(
            label: 'Credential a',
            baseUrl: 'https://sonarcloud.io',
            secret: 'squ_a',
            isDefault: false,
          );

      expect(
        container.read(sonarQubeCredentialFormNotifierProvider).error,
        isA<AppFailure>(),
      );
    },
  );
}
