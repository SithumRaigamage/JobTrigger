import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/credentials/active_github_credential_notifier.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/data/credentials/github_credentials_notifier.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/data/credentials/sonarqube_credentials_notifier.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/home/reachability_watcher.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_overview_screen.dart';
import 'package:job_trigger/presentation/features/tool_selection/active_tool_notifier.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';
import 'package:job_trigger/presentation/navigation/app_router.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _Repo implements SonarQubeRepository {
  _Repo(this.projects);

  final List<SonarQubeProject> projects;
  final Map<String, SonarQubeProjectSummary> summaries = {};
  Result<Map<String, SonarQubeProjectSummary>, AppFailure>? summaryResult;
  Result<SonarQubeProjectsPage, AppFailure>? projectsResult;

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) async =>
      projectsResult ??
      Ok(SonarQubeProjectsPage(projects: projects, total: projects.length));

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) async =>
      summaryResult ??
      Ok({
        for (final k in projectKeys)
          k:
              summaries[k] ??
              const SonarQubeProjectSummary(gate: QualityGateState.none),
      });

  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) async => const Ok([]);

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  }) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) => throw UnimplementedError();
}

class _Credential extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => const SonarQubeCredential(
    id: 'c',
    label: 'Local',
    baseUrl: 'http://sonar.test',
    secret: 't',
  );
}

class _NoSaved extends SonarQubeCredentialsNotifier {
  @override
  Future<List<SonarQubeCredential>> build() async => const [];
}

/// Jenkins is the default tool until one is chosen; give it no servers so its
/// Home makes no network request of its own during the test.
class _NoJenkinsServers extends CredentialsNotifier {
  @override
  Future<List<JenkinsServer>> build() async => const [];
}

class _NoSavedGitHub extends GitHubCredentialsNotifier {
  @override
  Future<List<GitHubCredential>> build() async => const [];
}

class _NoActiveGitHub extends ActiveGitHubCredentialNotifier {
  @override
  GitHubCredential? build() => null;
}

SonarQubeProject _p(String key, String name) =>
    SonarQubeProject(key: key, name: name, lastAnalysisDate: null);

const _failed = SonarQubeProjectSummary(
  gate: QualityGateState.failed,
  bugs: 3,
  vulnerabilities: 1,
  codeSmells: 10,
);

/// SonarQube takes History's place with an Overview tab, through the real
/// router. Its own file: it drives the whole app and is the one test here
/// that is sensitive to what other tests left behind.
void main() {
  group('the real router', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance =
          InMemorySharedPreferencesStore.empty();
    });

    testWidgets('SonarQube shows an Overview tab; other tools keep History', (
      tester,
    ) async {
      final repo = _Repo([_p('bad', 'Broken')])..summaries['bad'] = _failed;
      final overrides = <Override>[
        reachabilityWatcherProvider.overrideWith((ref) {}),
        credentialsNotifierProvider.overrideWith(_NoJenkinsServers.new),
        sonarQubeRepositoryProvider.overrideWithValue(repo),
        activeSonarQubeCredentialNotifierProvider.overrideWith(_Credential.new),
        sonarQubeCredentialsNotifierProvider.overrideWith(_NoSaved.new),
        gitHubCredentialsNotifierProvider.overrideWith(_NoSavedGitHub.new),
        activeGitHubCredentialNotifierProvider.overrideWith(
          _NoActiveGitHub.new,
        ),
      ];
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);
      container.listen(authNotifierProvider, (_, _) {});
      await container
          .read(authNotifierProvider.notifier)
          .setSession(const User(id: 'u1', email: 'a@b.com'), 'jwt');
      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // Jenkins' Home (the default tool) shows a spinner that never stops
      // here, since this test gives it no server: pump a little instead of
      // waiting for it to settle.
      Future<void> settleBriefly() async {
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      router.go(AppRoutes.home);
      await settleBriefly();

      container
          .read(activeToolNotifierProvider.notifier)
          .setActiveTool(CiTool.sonarqube);
      await settleBriefly();
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('History'), findsNothing);

      await tester.tap(find.text('Overview'));
      await tester.pumpAndSettle();
      expect(find.byType(SonarQubeOverviewScreen), findsOneWidget);
      expect(find.text('Broken'), findsOneWidget);

      // Another tool: History is back and Overview is gone.
      container
          .read(activeToolNotifierProvider.notifier)
          .setActiveTool(CiTool.githubActions);
      await tester.pumpAndSettle();
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Overview'), findsNothing);
      expect(find.byType(SonarQubeOverviewScreen), findsNothing);
    });
  });
}
