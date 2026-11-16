import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/credentials/active_github_credential_notifier.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/dashboard/dashboard_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_github_repository.dart';
import '../../../support/fake_jenkins_repository.dart';

const _server = JenkinsServer(
  id: 'a',
  serverName: 'Acme',
  jenkinsURL: 'https://a.test',
  username: 'u',
  secret: 's',
);

const _jobs = [
  JenkinsJob(
    name: 'api',
    url: 'https://a.test/job/api/',
    color: 'blue_anime',
    lastBuild: JenkinsBuild(number: 7, url: 'u', timestamp: 0, building: true),
  ),
  JenkinsJob(
    name: 'web',
    url: 'https://a.test/job/web/',
    color: 'red',
    lastBuild: JenkinsBuild(number: 12, url: 'u', timestamp: 0),
  ),
  JenkinsJob(
    name: 'billing',
    url: 'https://a.test/job/billing/',
    color: 'blue',
  ),
];

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => _server;
}

class _NoServer extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => null;
}

class _GitHub extends ActiveGitHubCredentialNotifier {
  @override
  GitHubCredential? build() =>
      const GitHubCredential(id: 'g', label: 'g', secret: 't');
}

class _NoGitHub extends ActiveGitHubCredentialNotifier {
  @override
  GitHubCredential? build() => null;
}

class _Sonar extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => const SonarQubeCredential(
    id: 's',
    label: 's',
    baseUrl: 'https://s.test',
    secret: 't',
  );
}

class _NoSonar extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => null;
}

class _Jenkins extends FakeJenkinsRepository {
  _Jenkins(this.result);

  final Result<List<JenkinsJob>, AppFailure> result;

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() async => result;

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobStatus(String url) async =>
      Ok(_jobs.firstWhere((job) => job.url == url));
}

/// Only the two calls the dashboard makes; the rest of the interface throws.
class _SonarRepo with SonarQubeInsightsDefaults implements SonarQubeRepository {
  _SonarRepo({required this.projects, required this.summaries});

  final List<SonarQubeProject> projects;
  final Map<String, SonarQubeProjectSummary> summaries;

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = 50,
  }) async =>
      Ok(SonarQubeProjectsPage(projects: projects, total: projects.length));

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) async {
    final result = <String, SonarQubeProjectSummary>{};
    for (final key in projectKeys) {
      final summary = summaries[key];
      if (summary != null) result[key] = summary;
    }
    return Ok(result);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// One endpoint each with a credential; the other two left unset.
ProviderContainer _container({
  Result<List<JenkinsJob>, AppFailure>? jenkinsTree,
  JenkinsServer? server = _server,
  FakeGitHubRepository? gitHub,
  bool withGitHubCredential = false,
  SonarQubeRepository? sonar,
  bool withSonarCredential = false,
}) {
  final container = ProviderContainer(
    overrides: [
      server == null
          ? activeServerNotifierProvider.overrideWith(_NoServer.new)
          : activeServerNotifierProvider.overrideWith(_Server.new),
      withGitHubCredential
          ? activeGitHubCredentialNotifierProvider.overrideWith(_GitHub.new)
          : activeGitHubCredentialNotifierProvider.overrideWith(_NoGitHub.new),
      withSonarCredential
          ? activeSonarQubeCredentialNotifierProvider.overrideWith(_Sonar.new)
          : activeSonarQubeCredentialNotifierProvider.overrideWith(
              _NoSonar.new,
            ),
      if (jenkinsTree != null)
        jenkinsRepositoryProvider.overrideWithValue(_Jenkins(jenkinsTree)),
      if (gitHub != null) gitHubRepositoryProvider.overrideWithValue(gitHub),
      if (sonar != null) sonarQubeRepositoryProvider.overrideWithValue(sonar),
    ],
  );
  addTearDown(container.dispose);
  container.listen(dashboardNotifierProvider, (_, _) {});
  return container;
}

/// Lets pins load from (mock) storage and the aggregate settle.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<DashboardData> _data(ProviderContainer container) async {
  await _settle();
  return container.read(dashboardNotifierProvider.future);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('lists failing and running Jenkins jobs, and the pins', () async {
    SharedPreferences.setMockInitialValues({
      'pinned_jobs_a':
          '[{"url":"https://a.test/job/billing/","label":"billing"}]',
    });
    final container = _container(jenkinsTree: const Ok(_jobs));

    final data = await _data(container);

    expect(data.failingCount, 1);
    expect(data.runningCount, 1);
    final failing = data.items.where((i) => i.group == DashboardGroup.failing);
    final running = data.items.where((i) => i.group == DashboardGroup.running);
    final pinned = data.items.where((i) => i.group == DashboardGroup.pinned);
    expect(failing.single.title, 'web');
    expect(failing.single.jenkinsJob?.url, 'https://a.test/job/web/');
    expect(running.single.title, 'api');
    expect(pinned.single.title, 'billing');
    expect(pinned.single.subtitle, 'No builds');
    expect(data.notSetUp, {
      DashboardSource.githubActions,
      DashboardSource.sonarqube,
    });
    expect(data.failures, isEmpty);
  });

  test('caps the rows per group but keeps the counts', () async {
    final many = [
      for (var i = 0; i < 12; i++)
        JenkinsJob(name: 'job$i', url: 'https://a.test/job/j$i/', color: 'red'),
    ];
    final container = _container(jenkinsTree: Ok(many));

    final data = await _data(container);

    expect(data.failingCount, 12);
    expect(
      data.items.where((i) => i.group == DashboardGroup.failing).length,
      dashboardItemsPerGroup,
    );
  });

  test('GitHub failures and active runs appear', () async {
    final gitHub = FakeGitHubRepository()
      ..reposResult = const Ok([
        GitHubRepo(id: 1, owner: 'acme', name: 'api', fullName: 'acme/api'),
      ])
      ..repoRuns['api'] = Ok([
        testRun(1, status: 'completed', conclusion: 'failure'),
        testRun(2, status: 'in_progress', conclusion: null),
        testRun(3, status: 'completed', conclusion: 'success'),
      ]);
    final container = _container(
      jenkinsTree: const Ok(_jobs),
      gitHub: gitHub,
      withGitHubCredential: true,
    );

    final data = await _data(container);

    final github = data.items.where(
      (i) => i.source == DashboardSource.githubActions,
    );
    expect(github.map((i) => i.title), ['acme/api #1', 'acme/api #2']);
    expect(github.first.githubRun?.conclusion, 'failure');
    expect(github.last.group, DashboardGroup.running);
  });

  test('SonarQube reports only projects whose gate needs attention', () async {
    final projects = [
      const SonarQubeProject(key: 'a', name: 'Alpha', lastAnalysisDate: null),
      const SonarQubeProject(key: 'b', name: 'Beta', lastAnalysisDate: null),
    ];
    final container = _container(
      jenkinsTree: const Ok(_jobs),
      withSonarCredential: true,
      sonar: _SonarRepo(
        projects: projects,
        summaries: const {
          'a': SonarQubeProjectSummary(gate: QualityGateState.failed),
          'b': SonarQubeProjectSummary(gate: QualityGateState.passed),
        },
      ),
    );

    final data = await _data(container);

    final quality = data.items.where((i) => i.group == DashboardGroup.quality);
    expect(quality.single.title, 'Alpha');
    expect(data.qualityCount, 1);
    expect(data.notSetUp, {DashboardSource.githubActions});
  });

  test('no credentials anywhere is "not set up", not an error', () async {
    final container = _container(server: null);

    final data = await _data(container);

    expect(data.items, isEmpty);
    expect(data.notSetUp, DashboardSource.values.toSet());
    expect(data.failures, isEmpty);
  });

  test('one tool failing leaves the others working', () async {
    final gitHub = FakeGitHubRepository()
      ..reposResult = const Ok([
        GitHubRepo(id: 1, owner: 'acme', name: 'api', fullName: 'acme/api'),
      ])
      ..repoRuns['api'] = Ok([
        testRun(1, status: 'completed', conclusion: 'failure'),
      ]);
    final container = _container(
      jenkinsTree: const Err(NetworkFailure()),
      gitHub: gitHub,
      withGitHubCredential: true,
    );

    final data = await _data(container);

    expect(data.failures[DashboardSource.jenkins], isA<NetworkFailure>());
    expect(
      data.items.where((i) => i.source == DashboardSource.githubActions),
      hasLength(1),
    );
  });
}
