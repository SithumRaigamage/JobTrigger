import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/github_credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/github_credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/settings/settings_screen.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Minimal fakes — only `fetchAll` is exercised by this smoke test.
class _FakeCredentialsRepository implements CredentialsRepository {
  _FakeCredentialsRepository(this._servers);

  final List<JenkinsServer> _servers;

  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      Ok(List.of(_servers));

  @override
  Future<Result<void, AppFailure>> delete(String id) => throw UnimplementedError();

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
  }) => throw UnimplementedError();

  @override
  Future<Result<JenkinsServer, AppFailure>> switchActive(String id) =>
      throw UnimplementedError();
}

class _FakeGitHubCredentialsRepository implements GitHubCredentialsRepository {
  _FakeGitHubCredentialsRepository(this._credentials);

  final List<GitHubCredential> _credentials;

  @override
  Future<Result<List<GitHubCredential>, AppFailure>> fetchAll() async =>
      Ok(List.of(_credentials));

  @override
  Future<Result<void, AppFailure>> delete(String id) => throw UnimplementedError();

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

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  testWidgets(
    'renders both the Jenkins and GitHub sections with their empty states, '
    'without throwing (P8-06 CustomScrollView/sliver restructuring smoke test)',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(
            _FakeCredentialsRepository(const []),
          ),
          gitHubCredentialsRepositoryProvider.overrideWithValue(
            _FakeGitHubCredentialsRepository(const []),
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
      expect(find.text('JENKINS SERVERS'), findsOneWidget);
      expect(find.text('GITHUB'), findsOneWidget);
      expect(find.text('No Servers Yet'), findsOneWidget);
      expect(find.text('No GitHub Credentials Yet'), findsOneWidget);
    },
  );

  testWidgets(
    'renders populated lists for both sections without throwing',
    (tester) async {
      const server = JenkinsServer(
        id: 's1',
        serverName: 'My Jenkins',
        jenkinsURL: 'https://jenkins.test',
        username: 'user',
        secret: 'pass',
        isDefault: true,
      );
      const credential = GitHubCredential(
        id: 'g1',
        label: 'Personal',
        secret: 'ghp_faketoken',
        isDefault: true,
      );
      final container = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(
            _FakeCredentialsRepository(const [server]),
          ),
          gitHubCredentialsRepositoryProvider.overrideWithValue(
            _FakeGitHubCredentialsRepository(const [credential]),
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
      expect(find.text('My Jenkins'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);
    },
  );
}
