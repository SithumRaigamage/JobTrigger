import 'dart:typed_data';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'jenkins_build.dart';
import 'jenkins_job.dart';
import 'log_chunk.dart';
import 'pending_input.dart';
import 'pipeline_stage.dart';
import 'queue_item.dart';
import 'test_report.dart';

abstract class JenkinsRepository {
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree();

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
  Future<Result<String?, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
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

  /// `GET {buildUrl}wfapi/pendingInputActions` (US-PIPE-05). Returns
  /// `Ok(null)` (not an [Err]) when nothing is paused — a normal state —
  /// or the first pending action when one or more exist (Jenkins can in
  /// principle report several; this app surfaces one at a time, matching
  /// the single-banner UI). **Unverified against a real paused pipeline**
  /// — see `pending_input.dart`'s doc comment.
  Future<Result<PendingInput?, AppFailure>> fetchPendingInput(String buildUrl);

  /// Resolves and approves/rejects a paused input step (US-PIPE-05).
  /// [buildUrl] + [inputId] construct `{buildUrl}input/{inputId}/`, then
  /// POST `proceedEmpty` (no params), `submit` (with [parameters], form-
  /// urlencoded) when [proceed] is true, or `abort` when false — the CSRF
  /// crumb (`NFR-SEC-06`) is attached automatically like every other
  /// Jenkins POST. **Unverified against a real paused pipeline** — see
  /// `pending_input.dart`'s doc comment; this is the highest-stakes call
  /// in the PIPE epic, confirm against a real server before trusting it.
  Future<Result<void, AppFailure>> submitInput({
    required String buildUrl,
    required String inputId,
    required bool proceed,
    Map<String, String> parameters,
  });
}
