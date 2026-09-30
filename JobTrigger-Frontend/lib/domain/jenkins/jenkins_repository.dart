import 'dart:typed_data';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'branch_kind.dart';
import 'jenkins_build.dart';
import 'jenkins_job.dart';
import 'log_chunk.dart';
import 'parameter_file.dart';
import 'pending_input.dart';
import 'pipeline_stage.dart';
import 'queue_item.dart';
import 'test_report.dart';

abstract class JenkinsRepository {
  /// The recursive crawl, 6 levels deep (`jobTreeCrawlDepth`) — used for
  /// cross-folder search and the global history timeline, not for browsing.
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree();

  /// One level of jobs: the server root when [folderUrl] is null, else that
  /// folder's direct children (P11-05). Home browses with this, so there's
  /// no depth limit and no whole-tree download on load (AUD-19/20).
  /// Children of a returned folder are `null` until that folder is fetched
  /// itself; `JenkinsJob.isFolder` still recognises it by class.
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(String? folderUrl);

  /// US-JX-03: which of a multibranch project's jobs are branches, pull
  /// requests, or tags, keyed by job `name`, from the project's views.
  Future<Result<Map<String, BranchKind>, AppFailure>> fetchBranchKinds(
    String multibranchUrl,
  );

  /// US-JX-03: "Scan repository now" — `POST {projectUrl}build?delay=0` on
  /// a multibranch project or organization folder. Jenkins answers with a
  /// 302 back to the project, which counts as success. Progress and the
  /// scan log come from [streamBuildLog] on `{projectUrl}indexing/`
  /// (`X-More-Data` is true while a scan runs).
  Future<Result<void, AppFailure>> scanMultibranch(String projectUrl);

  /// [jobUrl] is the job's already-rewritten absolute URL (from a
  /// previously-fetched tree), not a relative path.
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl);

  /// [buildUrl] is the build's already-rewritten absolute URL. [start] is
  /// the byte offset to resume from (0 for the first read).
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  });

  /// Last 20 builds for one job (per-job history, P5-16) — a separate
  /// fetch from [fetchJobDetail], per `JenkinsAPIService.fetchBuildHistory`
  /// (Swift).
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(String jobUrl);

  /// POSTs `build` (no params) or `buildWithParameters` (form-urlencoded),
  /// chosen the same way as `JenkinsAPIService.triggerJob` (Swift): use
  /// `buildWithParameters` if the job itself is parameterized OR
  /// [parameters] is non-empty. [paramToken] is appended as `?token=` when
  /// present, matching a Jenkins server configured to require it.
  ///
  /// Returns the rewritten queue-item URL from the response's `Location`
  /// header on success (US-PIPE-01), or `null` if Jenkins didn't send one
  /// — triggering still succeeded either way; a missing/unparseable
  /// `Location` only means this specific build can't be tracked through
  /// the queue, not that the request failed.
  ///
  /// With [files] (US-JX-02 file parameters) the body is
  /// `multipart/form-data`: each file is a part named after its parameter,
  /// alongside [parameters] as text parts. Verified on the fixture Jenkins.
  Future<Result<String?, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    Map<String, ParameterFile> files = const {},
    String? paramToken,
  });

  /// POSTs `{buildNumber}/stop` — [buildUrl] is the build's absolute URL
  /// (e.g. `.../job/x/20/`).
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl);

  /// `GET {queueItemUrl}api/json` (US-PIPE-01) — [queueItemUrl] is the
  /// already-rewritten URL returned by [triggerBuild]. Jenkins' queue is
  /// server-wide with no per-job endpoint, so this only tracks a specific
  /// item already known by URL, not "is this job currently queued."
  Future<Result<QueueItem, AppFailure>> fetchQueueItem(String queueItemUrl);

  /// `GET {buildUrl}testReport/api/json` (US-PIPE-06). Returns `Ok(null)`
  /// (not an [Err]) when the build has no published test report — a
  /// normal state (the job doesn't publish test results, or this build
  /// hasn't finished), surfaced as a real 404 from Jenkins.
  Future<Result<TestReport?, AppFailure>> fetchTestReport(String buildUrl);

  /// `GET {buildUrl}artifact/{relativePath}` (US-PIPE-07), authenticated
  /// via the same client as every other Jenkins request — deliberately
  /// not a bare external link, since that would either need embedding
  /// Basic Auth credentials in a URL (unsafe) or hit an external browser
  /// unauthenticated (401). The caller hands the returned bytes off via
  /// the OS share sheet rather than this app managing on-device file
  /// storage.
  Future<Result<Uint8List, AppFailure>> fetchArtifactBytes(
    String buildUrl,
    String relativePath,
  );

  /// `GET {buildUrl}wfapi/describe` (US-PIPE-04). Returns `Ok(null)` (not
  /// an [Err]) when the build isn't a pipeline job — a normal state
  /// (freestyle job, or the Pipeline: REST API plugin isn't installed),
  /// surfaced as a real 404 from Jenkins, same pattern as
  /// [fetchTestReport].
  Future<Result<List<PipelineStage>?, AppFailure>> fetchPipelineStages(
    String buildUrl,
  );

  /// `GET {buildUrl}execution/node/{stageId}/wfapi/describe` (US-JX-04): the
  /// steps inside one stage. `Ok(null)` on 404, meaning no Pipeline REST
  /// API, so the caller falls back to the full console.
  Future<Result<List<PipelineStep>?, AppFailure>> fetchStageSteps(
    String buildUrl,
    String stageId,
  );

  /// `GET {buildUrl}execution/node/{stepId}/wfapi/log` (US-JX-04).
  Future<Result<StepLog, AppFailure>> fetchStepLog(
    String buildUrl,
    String stepId,
  );

  /// `GET {buildUrl}wfapi/pendingInputActions` (US-PIPE-05). Returns
  /// `Ok(null)` (not an [Err]) when nothing is paused — a normal state —
  /// or the first pending action when one or more exist (Jenkins can in
  /// principle report several; this app surfaces one at a time, matching
  /// the single-banner UI). Verified against a real paused pipeline
  /// (P11-02, `test/fixture/input_step_fixture_test.dart`).
  Future<Result<PendingInput?, AppFailure>> fetchPendingInput(String buildUrl);

  /// Resolves and approves/rejects a paused input step (US-PIPE-05).
  /// [buildUrl] + [inputId] construct `{buildUrl}input/{inputId}/`, then
  /// POST `proceedEmpty` (no params) or `proceed` (with [parameters] as a
  /// Stapler `json` form field) when [proceed] is true, or `abort` when
  /// false. The CSRF crumb (`NFR-SEC-06`) is attached automatically like
  /// every other Jenkins POST. A user without `Job/Build` gets
  /// [PermissionFailure] (Jenkins answers that with a 400 page, not a 403), and
  /// an input someone else already handled gets [NotFoundFailure].
  /// Verified end to end on the fixture Jenkins (P11-02), which found and
  /// fixed the parameter encoding and permission mapping that P7-07 had
  /// guessed.
  Future<Result<void, AppFailure>> submitInput({
    required String buildUrl,
    required String inputId,
    required bool proceed,
    Map<String, String> parameters,
  });
}
