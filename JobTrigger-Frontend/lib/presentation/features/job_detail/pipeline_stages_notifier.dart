import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/pipeline_stage.dart';

part 'pipeline_stages_notifier.g.dart';

/// US-PIPE-04. Family-keyed by build URL — its own fetch, separate from
/// `JobDetailNotifier` (like `TestReportNotifier`, `wfapi/describe` isn't
/// embeddable in the job-detail `tree=` query). `null` data means the
/// build isn't a pipeline job, a normal state, not an error.
///
/// Kept live-updating while a build runs via `BuildStatusPollingNotifier`
/// invalidating this alongside `JobDetailNotifier` on the same 5s cadence
/// (`docs/user-stories/11-build-insights-pipeline.md`'s US-PIPE-04 asks
/// for this explicitly) — not polled independently here, to avoid two
/// separate timers doing the same job.
@riverpod
class PipelineStagesNotifier extends _$PipelineStagesNotifier {
  @override
  Future<List<PipelineStage>?> build(String buildUrl) async {
    final result = await ref
        .watch(jenkinsRepositoryProvider)
        .fetchPipelineStages(buildUrl);
    return result.fold((stages) => stages, (failure) => throw failure);
  }
}
