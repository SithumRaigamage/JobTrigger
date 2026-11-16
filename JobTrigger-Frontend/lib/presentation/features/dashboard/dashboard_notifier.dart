import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/credentials/active_github_credential_notifier.dart';
import '../../../data/credentials/active_server_notifier.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/github/github_repo.dart';
import '../../../domain/github/github_workflow.dart';
import '../../../domain/github/github_workflow_run.dart';
import '../../../domain/jenkins/history_filter.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../github/github_global_history_notifier.dart';
import '../home/pinned_jobs_notifier.dart';
import '../sonarqube/sonarqube_projects_notifier.dart';

part 'dashboard_notifier.g.dart';

/// Rows per group on the dashboard. The counts in the header are totals, so
/// a busy server says "12 failing" and still shows the first eight.
const dashboardItemsPerGroup = 8;

/// Pinned jobs whose status is fetched for the dashboard. Pins are also on
/// Home; the dashboard only needs the top few.
const dashboardPinnedCap = 6;

/// SonarQube projects asked about in one `measures/search` call (the API's
/// own limit is 100, the first page of projects is smaller than that).
const dashboardSonarProjectCap = 50;

/// Which tool a row came from, and which tool's data is missing.
enum DashboardSource { jenkins, githubActions, sonarqube }

/// What a row is about, and the order the dashboard shows groups in: what's
/// broken first, then what's moving, then what the user chose, then code
/// quality.
enum DashboardGroup { failing, running, pinned, quality }

/// One row on the unified dashboard (`NR-02`). Only one of the payload
/// fields is set, matching [source]; the screen uses it to open the same
/// detail route that tool's own screens open.
class DashboardItem {
  const DashboardItem({
    required this.group,
    required this.source,
    required this.title,
    required this.subtitle,
    this.jenkinsJob,
    this.sonarProject,
    this.githubRepo,
    this.githubWorkflow,
    this.githubRun,
  });

  final DashboardGroup group;
  final DashboardSource source;
  final String title;
  final String subtitle;

  /// Jenkins jobs (also used for pinned rows) open job detail.
  final JenkinsJob? jenkinsJob;

  /// SonarQube projects open the project screen.
  final SonarQubeProject? sonarProject;

  /// GitHub runs open the run detail with the repo and workflow they came
  /// from; the run carries its workflow's id and name, so the workflow is
  /// reconstructed from it (the feed doesn't fetch workflow objects).
  final GitHubRepo? githubRepo;
  final GitHubWorkflow? githubWorkflow;
  final GitHubWorkflowRun? githubRun;
}

/// Everything the dashboard shows, plus why a tool is absent, so one broken
/// or unconfigured tool never hides the others.
class DashboardData {
  const DashboardData({
    this.items = const [],
    this.failingCount = 0,
    this.runningCount = 0,
    this.qualityCount = 0,
    this.failures = const {},
    this.notSetUp = const {},
  });

  final List<DashboardItem> items;

  /// Totals before [dashboardItemsPerGroup] caps each group's rows.
  final int failingCount;
  final int runningCount;
  final int qualityCount;

  /// Tools that have a credential but whose data couldn't be loaded.
  final Map<DashboardSource, AppFailure> failures;

  /// Tools with no credential saved on this device.
  final Set<DashboardSource> notSetUp;

  bool get isEmpty => items.isEmpty;
}

/// The unified home dashboard (`NR-02`, `docs/improvement-plan.md`): failing
/// builds, running jobs and pinned items across Jenkins, GitHub Actions and
/// SonarQube on one screen.
///
/// Each tool is fetched independently and failures are reported per tool, so
/// a server that is down or a tool that was never set up leaves the rest of
/// the screen working. Read-only: it never triggers, cancels or approves
/// anything — those stay in each tool's own screens, and Jenkins keeps its
/// existing behaviour (`CLAUDE.md` §11).
@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  @override
  Future<DashboardData> build() async {
    // Read every provider before the first await, so a credential change or
    // a tool switch rebuilds this once, cleanly.
    final server = ref.watch(activeServerNotifierProvider);
    final pins = ref.watch(pinnedJobsNotifierProvider);
    final gitHubCredential = ref.watch(activeGitHubCredentialNotifierProvider);
    final sonarCredential = ref.watch(
      activeSonarQubeCredentialNotifierProvider,
    );
    final pinStatuses = [
      for (final pin in pins.take(dashboardPinnedCap))
        ref.watch(pinnedJobStatusProvider(pin.url).future),
    ];

    final jenkinsRepo = server == null
        ? null
        : ref.watch(jenkinsRepositoryProvider);
    final githubFeed = gitHubCredential == null
        ? null
        : ref.watch(gitHubGlobalHistoryNotifierProvider.future);
    final sonarProjects = sonarCredential == null
        ? null
        : ref.watch(sonarQubeProjectsNotifierProvider.future);
    final sonarRepo = sonarCredential == null
        ? null
        : ref.watch(sonarQubeRepositoryProvider);

    final byGroup = {
      for (final group in DashboardGroup.values) group: <DashboardItem>[],
    };
    final failures = <DashboardSource, AppFailure>{};
    final notSetUp = <DashboardSource>{};
    var failingCount = 0, runningCount = 0, qualityCount = 0;

    // Pinned jobs: stored on the device, so they show even with no tool
    // reachable. Their status needs Jenkins, and is skipped without it.
    for (final (index, pin) in pins.take(dashboardPinnedCap).indexed) {
      JenkinsJob? job;
      if (server != null) {
        try {
          job = await pinStatuses[index];
        } on Object {
          job = null;
        }
      }
      byGroup[DashboardGroup.pinned]!.add(
        DashboardItem(
          group: DashboardGroup.pinned,
          source: DashboardSource.jenkins,
          title: pin.label,
          subtitle: job == null ? 'Not found' : _jenkinsSubtitle(job),
          jenkinsJob: job,
        ),
      );
    }

    if (jenkinsRepo == null) {
      notSetUp.add(DashboardSource.jenkins);
    } else {
      try {
        final result = await jenkinsRepo.fetchJobTree();
        switch (result) {
          case Ok(:final value):
            final (failing, running) = _jenkinsGroups(value);
            failingCount = failing.length;
            runningCount = running.length;
            byGroup[DashboardGroup.failing]!.addAll(failing);
            byGroup[DashboardGroup.running]!.addAll(running);
          case Err(:final error):
            failures[DashboardSource.jenkins] = error;
        }
      } on Object catch (error) {
        failures[DashboardSource.jenkins] = _asFailure(error);
      }
    }

    if (githubFeed == null) {
      notSetUp.add(DashboardSource.githubActions);
    } else {
      try {
        final feed = await githubFeed;
        for (final entry in feed.entries) {
          final run = entry.run;
          final group = _githubGroup(run);
          if (group == null) continue;
          if (group == DashboardGroup.failing) {
            failingCount++;
          } else {
            runningCount++;
          }
          byGroup[group]!.add(
            DashboardItem(
              group: group,
              source: DashboardSource.githubActions,
              title: '${entry.repo.fullName} #${run.runNumber}',
              subtitle: '${run.workflowName ?? run.title} · ${run.label}',
              githubRepo: entry.repo,
              githubWorkflow: _workflowOf(run),
              githubRun: run,
            ),
          );
        }
      } on Object catch (error) {
        failures[DashboardSource.githubActions] = _asFailure(error);
      }
    }

    if (sonarProjects == null || sonarRepo == null) {
      notSetUp.add(DashboardSource.sonarqube);
    } else {
      try {
        final page = await sonarProjects;
        final keys = page.projects
            .take(dashboardSonarProjectCap)
            .map((project) => project.key)
            .toList();
        if (keys.isNotEmpty) {
          final result = await sonarRepo.fetchProjectSummaries(keys);
          switch (result) {
            case Ok(:final value):
              for (final project in page.projects) {
                final summary = value[project.key];
                if (summary == null || !summary.needsAttention) continue;
                qualityCount++;
                byGroup[DashboardGroup.quality]!.add(
                  DashboardItem(
                    group: DashboardGroup.quality,
                    source: DashboardSource.sonarqube,
                    title: project.name,
                    subtitle: 'Quality gate ${summary.gate.name}',
                    sonarProject: project,
                  ),
                );
              }
            case Err(:final error):
              failures[DashboardSource.sonarqube] = error;
          }
        }
      } on Object catch (error) {
        failures[DashboardSource.sonarqube] = _asFailure(error);
      }
    }

    return DashboardData(
      items: [
        for (final group in DashboardGroup.values)
          ...byGroup[group]!.take(dashboardItemsPerGroup),
      ],
      failingCount: failingCount,
      runningCount: runningCount,
      qualityCount: qualityCount,
      failures: failures,
      notSetUp: notSetUp,
    );
  }

  /// Jenkins' ball colours, the same rule Home and the summary strip use: a
  /// job that is building is Running whatever its last result was.
  static (List<DashboardItem>, List<DashboardItem>) _jenkinsGroups(
    List<JenkinsJob> jobs,
  ) {
    final failing = <DashboardItem>[];
    final running = <DashboardItem>[];
    for (final job in jobs) {
      if (job.isFolder) continue;
      final color = job.color?.toLowerCase() ?? '';
      final building =
          color.endsWith('_anime') || (job.lastBuild?.building ?? false);
      final group = building
          ? DashboardGroup.running
          : color == 'red'
          ? DashboardGroup.failing
          : null;
      if (group == null) continue;
      final item = DashboardItem(
        group: group,
        source: DashboardSource.jenkins,
        title: job.label,
        subtitle: _jenkinsSubtitle(job),
        jenkinsJob: job,
      );
      (group == DashboardGroup.running ? running : failing).add(item);
    }
    return (failing, running);
  }

  /// "folder / job · #12", so a dashboard row says which job it is without
  /// opening it.
  static String _jenkinsSubtitle(JenkinsJob job) {
    final path = folderPathOf(job.url);
    final number = job.lastBuild?.number;
    return [
      if (path.isNotEmpty) path,
      if (number != null) '#$number' else 'No builds',
    ].join(' · ');
  }

  /// Failing and running runs; finished successes and skips aren't news.
  static DashboardGroup? _githubGroup(GitHubWorkflowRun run) {
    if (run.isActive) return DashboardGroup.running;
    return switch (run.conclusion) {
      'failure' || 'timed_out' || 'startup_failure' => DashboardGroup.failing,
      _ => null,
    };
  }

  /// The feed's runs carry their workflow's id and name; the detail screen
  /// shows the name (and back-navigates), so that's all that's rebuilt.
  static GitHubWorkflow _workflowOf(GitHubWorkflowRun run) => GitHubWorkflow(
    id: run.workflowId ?? 0,
    name: run.workflowName ?? 'Workflow',
    path: '',
    state: 'active',
  );

  static AppFailure _asFailure(Object error) =>
      error is AppFailure ? error : const UnknownFailure();
}
