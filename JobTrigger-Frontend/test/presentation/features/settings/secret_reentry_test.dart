import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/datasources/github_client_factory.dart';
import 'package:job_trigger/data/datasources/jenkins_client_factory.dart';
import 'package:job_trigger/data/datasources/sonarqube_client_factory.dart';
import 'package:job_trigger/data/models/credential/credential_dto.dart';
import 'package:job_trigger/data/models/credential/github_credential_dto.dart';
import 'package:job_trigger/data/models/credential/sonarqube_credential_dto.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/github_credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/sonarqube_credentials_repository_impl.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/domain/auth/auth_validation.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/github_credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/credential/sonarqube_credentials_repository.dart';
import 'package:job_trigger/presentation/features/settings/github_credential_edit_bottom_sheet.dart';
import 'package:job_trigger/presentation/features/settings/github_credential_form_notifier.dart';
import 'package:job_trigger/presentation/features/settings/server_edit_bottom_sheet.dart';
import 'package:job_trigger/presentation/features/settings/server_form_notifier.dart';
import 'package:job_trigger/presentation/features/settings/settings_screen.dart';
import 'package:job_trigger/presentation/features/settings/sonarqube_credential_edit_bottom_sheet.dart';
import 'package:job_trigger/presentation/features/settings/sonarqube_credential_form_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// AUD-63 (P13-21): one credential whose secret the backend could not
/// decrypt must not fail the whole credential list, and the app must not
/// silently treat it as a working credential either.
///
/// The backend flags such a credential with `needsReentry: true` and sends
/// a null secret. These tests pin the four halves of the client contract:
/// the wire shape, the request the client builds, the save path, and what
/// the user sees.

class _FakeCredentialsRepository implements CredentialsRepository {
  _FakeCredentialsRepository(this._servers);

  final List<JenkinsServer> _servers;

  /// Set when the form tries to write — proves the blank-secret guard
  /// stops the write before it reaches the backend.
  int updateCalls = 0;
  String? lastUpdatedSecret;

  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      Ok(List.of(_servers));

  @override
  Future<Result<JenkinsServer, AppFailure>> add({
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) => throw UnimplementedError();

  @override
  Future<Result<JenkinsServer, AppFailure>> update(
    String id, {
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) async {
    updateCalls++;
    lastUpdatedSecret = secret;
    return Ok(
      JenkinsServer(
        id: id,
        serverName: serverName,
        jenkinsURL: jenkinsURL,
        username: username,
        secret: secret,
        isDefault: isDefault,
      ),
    );
  }

  @override
  Future<Result<void, AppFailure>> delete(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<JenkinsServer, AppFailure>> switchActive(String id) =>
      throw UnimplementedError();
}

class _FakeGitHubCredentialsRepository
    implements GitHubCredentialsRepository {
  _FakeGitHubCredentialsRepository(this._credentials);

  final List<GitHubCredential> _credentials;
  int updateCalls = 0;
  String? lastUpdatedSecret;

  @override
  Future<Result<List<GitHubCredential>, AppFailure>> fetchAll() async =>
      Ok(List.of(_credentials));

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
  }) async {
    updateCalls++;
    lastUpdatedSecret = secret;
    return Ok(
      GitHubCredential(
        id: id,
        label: label,
        secret: secret,
        defaultOwner: defaultOwner,
        isDefault: isDefault,
      ),
    );
  }

  @override
  Future<Result<void, AppFailure>> delete(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<GitHubCredential, AppFailure>> switchActive(String id) =>
      throw UnimplementedError();
}

class _FakeSonarQubeCredentialsRepository
    implements SonarQubeCredentialsRepository {
  _FakeSonarQubeCredentialsRepository(this._credentials);

  final List<SonarQubeCredential> _credentials;
  int updateCalls = 0;
  String? lastUpdatedSecret;

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
  }) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeCredential, AppFailure>> update(
    String id, {
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    bool isDefault = false,
  }) async {
    updateCalls++;
    lastUpdatedSecret = secret;
    return Ok(
      SonarQubeCredential(
        id: id,
        label: label,
        baseUrl: baseUrl,
        secret: secret,
        defaultOrganization: defaultOrganization,
        isDefault: isDefault,
      ),
    );
  }

  @override
  Future<Result<void, AppFailure>> delete(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<SonarQubeCredential, AppFailure>> switchActive(String id) =>
      throw UnimplementedError();
}

const _unreadableServer = JenkinsServer(
  id: 's1',
  serverName: 'My Jenkins',
  jenkinsURL: 'https://jenkins.test',
  username: 'user',
  secret: null,
  needsReentry: true,
);

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  group('wire contract', () {
    test('an unreadable Jenkins secret arrives as a null secret + flag', () {
      final dto = CredentialDto.fromJson({
        '_id': 'cred-1',
        'serverName': 'Prod Jenkins',
        'jenkinsURL': 'https://jenkins.example.com',
        'username': 'admin',
        'password': null,
        'needsReentry': true,
      });

      final domain = dto.toDomain();
      expect(domain.secret, isNull);
      expect(domain.needsReentry, isTrue);
    });

    test('a readable Jenkins secret arrives as a plain secret', () {
      final dto = CredentialDto.fromJson({
        '_id': 'cred-1',
        'serverName': 'Prod Jenkins',
        'jenkinsURL': 'https://jenkins.example.com',
        'username': 'admin',
        'password': 's3cret',
        'needsReentry': false,
      });

      final domain = dto.toDomain();
      expect(domain.secret, 's3cret');
      expect(domain.needsReentry, isFalse);
    });

    test(
      'the flag and the secret can never disagree — a null secret always '
      'means re-entry, whatever the server said',
      () {
        // A backend that sends `needsReentry: false` alongside a null
        // secret is wrong, and the client must not take its word for it:
        // a null secret IS the unreadable case.
        final dto = CredentialDto.fromJson({
          '_id': 'cred-1',
          'serverName': 'Prod Jenkins',
          'jenkinsURL': 'https://jenkins.example.com',
          'username': 'admin',
          'password': null,
          'needsReentry': false,
        });

        expect(dto.toDomain().needsReentry, isTrue);
      },
    );

    test('the GitHub and SonarQube DTOs carry the same contract', () {
      final github = GitHubCredentialDto.fromJson({
        '_id': 'gh-1',
        'label': 'Work',
        'token': null,
        'needsReentry': true,
      }).toDomain();
      expect(github.secret, isNull);
      expect(github.needsReentry, isTrue);

      final sonar = SonarQubeCredentialDto.fromJson({
        '_id': 'sq-1',
        'label': 'Work',
        'baseUrl': 'https://sonarcloud.io',
        'token': null,
        'needsReentry': true,
      }).toDomain();
      expect(sonar.secret, isNull);
      expect(sonar.needsReentry, isTrue);
    });

    test('one unreadable credential does not fail the whole list', () {
      // The list endpoint returns every credential; only the unreadable
      // one has a null secret. The client must still parse all of them.
      final list = [
        CredentialDto.fromJson({
          '_id': 'cred-1',
          'serverName': 'Good',
          'jenkinsURL': 'https://good.test',
          'username': 'admin',
          'password': 's3cret',
          'needsReentry': false,
        }),
        CredentialDto.fromJson({
          '_id': 'cred-2',
          'serverName': 'Broken',
          'jenkinsURL': 'https://broken.test',
          'username': 'admin',
          'password': null,
          'needsReentry': true,
        }),
        CredentialDto.fromJson({
          '_id': 'cred-3',
          'serverName': 'Also good',
          'jenkinsURL': 'https://good2.test',
          'username': 'admin',
          'password': 'other',
          'needsReentry': false,
        }),
      ];

      final domains = list.map((dto) => dto.toDomain()).toList();
      expect(domains, hasLength(3));
      expect(domains.map((d) => d.needsReentry), [false, true, false]);
      expect(domains[1].secret, isNull);
    });
  });

  group('request construction', () {
    test('a null Jenkins secret sends no Authorization header', () {
      final dio = buildJenkinsDio(
        baseUrl: 'https://jenkins.test',
        username: 'user',
        password: null,
      );

      expect(dio.options.headers.containsKey('Authorization'), isFalse);
    });

    test('a present Jenkins secret still sends Basic Auth', () {
      final dio = buildJenkinsDio(
        baseUrl: 'https://jenkins.test',
        username: 'user',
        password: 'pass',
      );

      expect(
        dio.options.headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('user:pass'))}',
      );
    });

    test('a null GitHub token sends no Authorization header', () {
      final dio = buildGitHubDio(token: null);

      expect(dio.options.headers.containsKey('Authorization'), isFalse);
      expect(buildGitHubDio(token: 'ghp_x').options.headers['Authorization'],
          'Bearer ghp_x');
    });

    test('a null SonarQube token sends no Authorization header', () {
      final dio = buildSonarQubeDio(
        baseUrl: 'https://sonarcloud.io',
        token: null,
      );

      expect(dio.options.headers.containsKey('Authorization'), isFalse);
      expect(
        buildSonarQubeDio(baseUrl: 'https://sonarcloud.io', token: 'squ_x')
            .options
            .headers['Authorization'],
        'Bearer squ_x',
      );
    });
  });

  group('save path', () {
    test('a blank secret is refused when the stored one was unreadable', () async {
      final repo = _FakeCredentialsRepository([_unreadableServer]);
      final container = ProviderContainer(
        overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(serverFormNotifierProvider, (_, _) {});

      await container
          .read(serverFormNotifierProvider.notifier)
          .save(
            id: 's1',
            serverName: 'My Jenkins',
            jenkinsURL: 'https://jenkins.test',
            username: 'user',
            secret: '',
            isDefault: false,
            needsReentry: true,
          );

      expect(
        container.read(serverFormNotifierProvider).error,
        isA<FormValidationError>(),
      );
      // The write never reached the backend — a blank would have
      // overwritten the stored secret for good.
      expect(repo.updateCalls, 0);
    });

    test('a re-entered secret is accepted and saved', () async {
      final repo = _FakeCredentialsRepository([_unreadableServer]);
      final container = ProviderContainer(
        overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(serverFormNotifierProvider, (_, _) {});
      container.listen(credentialsNotifierProvider, (_, _) {});

      await container
          .read(serverFormNotifierProvider.notifier)
          .save(
            id: 's1',
            serverName: 'My Jenkins',
            jenkinsURL: 'https://jenkins.test',
            username: 'user',
            secret: 'fresh-token',
            isDefault: false,
            needsReentry: true,
          );

      expect(container.read(serverFormNotifierProvider).hasError, isFalse);
      expect(repo.updateCalls, 1);
      expect(repo.lastUpdatedSecret, 'fresh-token');
    });

    test('the guard only fires for an unreadable credential', () async {
      // A readable credential is not blocked — the guard is about the
      // unreadable case specifically, not about blanks in general.
      final repo = _FakeCredentialsRepository([
        const JenkinsServer(
          id: 's1',
          serverName: 'My Jenkins',
          jenkinsURL: 'https://jenkins.test',
          username: 'user',
          secret: 'pass',
        ),
      ]);
      final container = ProviderContainer(
        overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(serverFormNotifierProvider, (_, _) {});
      container.listen(credentialsNotifierProvider, (_, _) {});

      await container
          .read(serverFormNotifierProvider.notifier)
          .save(
            id: 's1',
            serverName: 'My Jenkins',
            jenkinsURL: 'https://jenkins.test',
            username: 'user',
            secret: '',
            isDefault: false,
            needsReentry: false,
          );

      expect(container.read(serverFormNotifierProvider).hasError, isFalse);
      expect(repo.updateCalls, 1);
    });

    test('the GitHub form refuses to blank an unreadable token', () async {
      final repo = _FakeGitHubCredentialsRepository(const []);
      final container = ProviderContainer(
        overrides: [gitHubCredentialsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(gitHubCredentialFormNotifierProvider, (_, _) {});

      await container
          .read(gitHubCredentialFormNotifierProvider.notifier)
          .save(
            id: 'gh-1',
            label: 'Work',
            secret: '',
            isDefault: false,
            needsReentry: true,
          );

      expect(
        container.read(gitHubCredentialFormNotifierProvider).error,
        isA<FormValidationError>(),
      );
      expect(repo.updateCalls, 0);
    });

    test('the SonarQube form refuses to blank an unreadable token', () async {
      final repo = _FakeSonarQubeCredentialsRepository(const []);
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
            id: 'sq-1',
            label: 'Work',
            baseUrl: 'https://sonarcloud.io',
            secret: '',
            isDefault: false,
            needsReentry: true,
          );

      expect(
        container.read(sonarQubeCredentialFormNotifierProvider).error,
        isA<FormValidationError>(),
      );
      expect(repo.updateCalls, 0);
    });
  });

  group('what the user sees', () {
    testWidgets('a credential needing re-entry is flagged in the list', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(
            _FakeCredentialsRepository([_unreadableServer]),
          ),
          gitHubCredentialsRepositoryProvider.overrideWithValue(
            _FakeGitHubCredentialsRepository(const []),
          ),
          sonarQubeCredentialsRepositoryProvider.overrideWithValue(
            _FakeSonarQubeCredentialsRepository(const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Secret needs re-entering'), findsOneWidget);
      // The credential is still listed — that was the whole point.
      expect(find.text('My Jenkins'), findsOneWidget);
    });

    testWidgets('a readable credential shows no re-entry notice', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(
            _FakeCredentialsRepository([
              const JenkinsServer(
                id: 's1',
                serverName: 'My Jenkins',
                jenkinsURL: 'https://jenkins.test',
                username: 'user',
                secret: 'pass',
              ),
            ]),
          ),
          gitHubCredentialsRepositoryProvider.overrideWithValue(
            _FakeGitHubCredentialsRepository(const []),
          ),
          sonarQubeCredentialsRepositoryProvider.overrideWithValue(
            _FakeSonarQubeCredentialsRepository(const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Secret needs re-entering'), findsNothing);
    });

    testWidgets('the edit sheet explains why the secret must be re-entered', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1800);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ServerEditBottomSheet(existing: _unreadableServer),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Secret needs re-entering'), findsOneWidget);
      expect(
        find.textContaining('could not be read'),
        findsOneWidget,
      );
    });

    testWidgets('the GitHub edit sheet asks for the token again', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1800);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: GitHubCredentialEditBottomSheet(
                  existing: GitHubCredential(
                    id: 'gh-1',
                    label: 'Work',
                    secret: null,
                    needsReentry: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Secret needs re-entering'), findsOneWidget);
      // "Leave blank to keep the current token" would be a lie — there's
      // no current token to keep.
      expect(find.text('Leave blank to keep the current token'), findsNothing);
      expect(find.text('Enter the token again'), findsOneWidget);
    });

    testWidgets('the SonarQube edit sheet asks for the token again', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1800);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SonarQubeCredentialEditBottomSheet(
                  existing: SonarQubeCredential(
                    id: 'sq-1',
                    label: 'Work',
                    baseUrl: 'https://sonarcloud.io',
                    secret: null,
                    needsReentry: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Secret needs re-entering'), findsOneWidget);
      expect(find.text('Leave blank to keep the current token'), findsNothing);
    });
  });
}
