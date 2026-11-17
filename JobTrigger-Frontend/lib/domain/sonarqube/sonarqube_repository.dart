import '../../domain/sonarqube/sonarqube_server_info.dart';
import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'sonarqube_analysis.dart';
import 'sonarqube_branch_ref.dart';
import 'sonarqube_analysis_status.dart';
import 'sonarqube_hotspot.dart';
import 'sonarqube_issue.dart';
import 'sonarqube_issue_actions.dart';
import 'sonarqube_issue_grouping.dart';
import 'sonarqube_measure_history.dart';
import 'sonarqube_worst_files.dart';
import 'sonarqube_measure_delta.dart';
import 'sonarqube_metrics.dart';
import 'sonarqube_project.dart';
import 'sonarqube_project_summary.dart';
import 'sonarqube_quality_gate.dart';

/// SonarQube data access — independent of the Jenkins and GitHub
/// repositories (`NFR-SEC-03`). A code-quality viewer: everything is a read,
/// with nothing to trigger or cancel, **except** the four changes of batch 7
/// (assign, change status, comment, review a hotspot), which are the only
/// writes and are marked as such below. Grown one method per SQ task, as
/// `GitHubRepository` was.
abstract class SonarQubeRepository {
  /// The projects the credential's user can browse (`US-SQ-PROJ-01`), one
  /// [page] (1-based) of [pageSize] at a time. Uses `api/components/
  /// search_projects`, which any user with Browse access may call; a server
  /// without it falls back to the administrator-only `api/projects/search`.
  /// Sends `organization` when the credential has one (SonarCloud). A
  /// refusal is [SonarQubeAccessDeniedFailure]; a SonarCloud organization
  /// that doesn't exist is [SonarQubeOrganizationNotFoundFailure].
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  });

  /// `GET api/qualitygates/project_status?projectKey=` (`US-SQ-QUALITY-01`).
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  );

  /// `GET api/components/show?component=` (`US-SQ-LINK-02`): one project by
  /// its key, so a deep link can open it without loading the whole list. A
  /// key that is not a project this user can browse is
  /// [SonarQubeProjectNotFoundFailure].
  Future<Result<SonarQubeProject, AppFailure>> fetchProjectByKey(
    String projectKey,
  );

  /// `GET api/measures/component` for `sonarQubeMeasureKeys`
  /// (`US-SQ-QUALITY-02`). Keyed by metric; a metric the server didn't
  /// compute is simply absent, so the UI can show "—" rather than 0.
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  );

  /// `GET api/issues/search` (`US-SQ-QUALITY-03`), unresolved issues only,
  /// filtered and paged by the server. [page] is 1-based;
  /// [sonarQubeIssuesPageSize] per page. SonarQube refuses to page past
  /// 10,000 results, so the list ends there however large [total] is.
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
    SonarQubeIssueGrouping grouping = SonarQubeIssueGrouping.none,
  });

  /// `GET api/project_analyses/search?project=` (`US-SQ-QUALITY-04`): the
  /// latest [sonarQubeAnalysesLimit] analyses, newest first.
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  );

  /// `GET api/measures/search` (`US-SQ-PROJ-03`): the headline numbers and
  /// gate verdict for many projects in one request per
  /// [sonarQubeSummaryBatchSize]. Every key asked for is in the result; one
  /// with no gate result is [QualityGateState.none].
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys);

  /// The unresolved issues assigned to the credential's own user, across
  /// every project they can browse (`US-SQ-ISSUES-01`):
  /// `GET api/issues/search?assignees=__me__&resolved=false`, with no
  /// `componentKeys`. Each issue carries its project key and, when the
  /// lookup succeeds, its name.
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchMyIssues({
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  });

  /// Unresolved issues across every project the user can browse that match
  /// [term] in [field] (`US-SQ-ISSUES-03`): a rule key, a tag, a file path or
  /// an issue key, each an exact server-side filter of `api/issues/search`
  /// (which has no free-text parameter). Paged like [fetchMyIssues].
  Future<Result<SonarQubeIssuePage, AppFailure>> searchIssues(
    String term, {
    SonarQubeIssueSearchField field = SonarQubeIssueSearchField.rule,
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  });

  /// `GET api/ce/component?component=` (`US-SQ-CE-01`): the scan running
  /// now, anything queued, and whether the newest task failed. No polling;
  /// read when the page opens and on pull-to-refresh, like the rest.
  Future<Result<SonarQubeAnalysisStatus, AppFailure>> fetchAnalysisStatus(
    String projectKey,
  );

  /// `GET api/measures/component` for `sonarQubeNewCodeMetricKeys`
  /// (`US-SQ-QUALITY-08`): the numbers the gate is judged on. Whatever the
  /// server computes is returned; a server that reports no new-code values
  /// returns an empty map, and the app hides the switch rather than
  /// inventing zeros.
  Future<Result<Map<String, String>, AppFailure>> fetchNewCodeMeasures(
    String projectKey,
  );

  /// `GET api/measures/search_history?ps=2` (`US-SQ-QUALITY-09`): each
  /// measure's change since the previous analysis. A measure with fewer
  /// than two points is simply absent.
  Future<Result<List<SonarQubeMeasureDelta>, AppFailure>> fetchMeasureDeltas(
    String projectKey, {
    List<String> metricKeys = sonarQubeMeasureKeys,
  });

  /// `api/server/version` plus `api/system/status` (`US-SQ-SERVER-01`):
  /// the server's version and whether it is up, for telling a server problem
  /// from an app problem. Administrator-only endpoints are not used.
  Future<Result<SonarQubeServerInfo, AppFailure>> fetchServerInfo();

  /// `api/project_branches/list` plus `api/project_pull_requests/list`
  /// (`US-SQ-QUALITY-10`): everything analysed except the main branch, empty
  /// on editions that only analyse main.
  Future<Result<SonarQubeRefChoices, AppFailure>> fetchProjectRefs(
    String projectKey,
  );

  /// `GET api/measures/component_tree` (`US-SQ-QUALITY-12`): the ten files
  /// worst for [metric], file level, sorted on the server.
  Future<Result<SonarQubeWorstFiles, AppFailure>> fetchWorstFiles(
    String projectKey,
    SonarQubeFileMetric metric,
  );

  /// `GET api/issues/search?componentKeys=` (`US-SQ-QUALITY-12`): a single
  /// file's open issues, for the tap-through.
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchFileIssues(
    String componentKey,
  );

  /// `GET api/measures/search_history` (`US-SQ-QUALITY-11`): one measure's
  /// points over time, oldest first. Points the server reports without a
  /// value are dropped.
  Future<Result<SonarQubeMeasureHistory, AppFailure>> fetchMeasureHistory(
    String projectKey,
    String metric,
  );

  /// `GET api/hotspots/search?project=` (`US-SQ-HOTSPOT-01`): a project's
  /// security hotspots, filtered by the server to [reviewed] ones or the
  /// ones still to review. Reviewing itself is a write (`US-SQ-WRITE-04`).
  Future<Result<SonarQubeHotspotPage, AppFailure>> fetchHotspots(
    String projectKey, {
    bool reviewed = false,
    int page = 1,
  });

  /// `GET api/hotspots/show` plus the code around it (`US-SQ-HOTSPOT-01`):
  /// the rule's name and the snippet the same way an issue's page shows them.
  Future<Result<SonarQubeHotspotDetail, AppFailure>> fetchHotspotDetail(
    String hotspotKey,
  );

  /// `GET api/issues/search?issues=&additionalFields=transitions,comments`
  /// (`US-SQ-WRITE-01..03`): the issue's current status and assignee, the
  /// transitions the server offers for it and its comments.
  Future<Result<SonarQubeIssueDetail, AppFailure>> fetchIssueDetail(
    String issueKey,
  );

  // ---- The first writes in this epic (batch 7). Each is one `POST`, sent as
  // a form body, and returns only whether the server accepted it: callers
  // re-read the issue afterwards instead of assuming the result. A 403 is
  // [SonarQubeWriteDeniedFailure].

  /// `POST api/issues/assign` (`US-SQ-WRITE-01`). [assignee] is a login,
  /// [sonarQubeAssignToMe] for the token's own user, or empty to unassign.
  /// (Found against a real server: `api/issues/search` takes `__me__` but
  /// `assign` answers "Unknown user: __me__" and wants `_me`.)
  Future<Result<void, AppFailure>> assignIssue(
    String issueKey,
    String assignee,
  );

  /// `POST api/issues/do_transition` (`US-SQ-WRITE-02`).
  Future<Result<void, AppFailure>> transitionIssue(
    String issueKey,
    String transition,
  );

  /// `POST api/issues/add_comment` (`US-SQ-WRITE-03`).
  Future<Result<void, AppFailure>> addIssueComment(
    String issueKey,
    String text,
  );

  /// `POST api/hotspots/change_status` (`US-SQ-WRITE-04`).
  Future<Result<void, AppFailure>> reviewHotspot(
    String hotspotKey,
    SonarQubeHotspotReview review, {
    String? comment,
  });

  /// What an issue's page shows besides the issue (`US-SQ-QUALITY-06`): the
  /// rule's name (`api/rules/show`) and the code around it
  /// (`api/sources/show`), fetched together. One failing leaves the other; if
  /// both fail the failure is returned.
  Future<Result<SonarQubeIssueContext, AppFailure>> fetchIssueContext(
    SonarQubeIssue issue,
  );
}

/// `ps` for `api/projects/search`; 500 is SonarQube's maximum.
const sonarQubeProjectsPageSize = 500;

/// What `api/issues/assign` calls the token's own user.
const sonarQubeAssignToMe = '_me';
