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
import 'package:job_trigger/presentation/features/tool_selection/active_tool_notifier.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Minimal fakes — only `fetchAll` is exercised by this smoke test.
class _FakeCredentialsRepository implements CredentialsRepository {
  _FakeCredentialsRepository(this._servers);

  final List<JenkinsServer> _servers;

  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      Ok(List.of(_servers));

  @override
  Future<Result<void, AppFailure>> delete(String id) =>
      throw UnimplementedError();

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
  Future<Result<void, AppFailure>> delete(String id) =>
      throw UnimplementedError();

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
    'shows only the Jenkins section (with its empty state) when Jenkins is '
    'the active tool -- default/null tool falls back to Jenkins',
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
      expect(find.text('No Servers Yet'), findsOneWidget);
      expect(find.text('GITHUB'), findsNothing);
      expect(find.text('No GitHub Credentials Yet'), findsNothing);
    },
  );

  testWidgets(
    'shows only the GitHub section (with its empty state) when GitHub '
    'Actions is the active tool -- the exact case a real user hit: '
    'selecting Jenkins must not surface a GitHub credentials prompt, and '
    'vice versa',
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

      // Set the active tool only once SettingsScreen is mounted and
      // watching -- activeToolNotifierProvider is a plain autoDispose
      // provider, so setting it before anything observes it risks it
      // resetting before this test's widget ever sees the change (same
      // pitfall documented in app_router_test.dart).
      container
          .read(activeToolNotifierProvider.notifier)
          .setActiveTool(CiTool.githubActions);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('GITHUB'), findsOneWidget);
      expect(find.text('No GitHub Credentials Yet'), findsOneWidget);
      expect(find.text('JENKINS SERVERS'), findsNothing);
      expect(find.text('No Servers Yet'), findsNothing);
    },
  );

  testWidgets(
    'renders a populated Jenkins list when Jenkins is active, without '
    'throwing',
    (tester) async {
      const server = JenkinsServer(
        id: 's1',
        serverName: 'My Jenkins',
        jenkinsURL: 'https://jenkins.test',
        username: 'user',
        secret: 'pass',
        isDefault: true,
      );
      final container = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(
            _FakeCredentialsRepository(const [server]),
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
      expect(find.text('My Jenkins'), findsOneWidget);
    },
  );

  testWidgets('renders a populated GitHub list when GitHub Actions is active, '
      'without throwing', (tester) async {
    const credential = GitHubCredential(
      id: 'g1',
      label: 'Personal',
      secret: 'ghp_faketoken',
      isDefault: true,
    );
    final container = ProviderContainer(
      overrides: [
        credentialsRepositoryProvider.overrideWithValue(
          _FakeCredentialsRepository(const []),
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

    container
        .read(activeToolNotifierProvider.notifier)
        .setActiveTool(CiTool.githubActions);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Personal'), findsOneWidget);
  });
}
