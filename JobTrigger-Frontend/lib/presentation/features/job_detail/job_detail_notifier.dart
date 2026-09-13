import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';

part 'job_detail_notifier.g.dart';

/// Fetches one job's detail (params, health, last build) — family-keyed by
/// the job's absolute URL. Standard shape from `docs/architecture.md §4`.
@riverpod
class JobDetailNotifier extends _$JobDetailNotifier {
  @override
  Future<JenkinsJob> build(String jobUrl) async {
    final result = await ref
        .watch(jenkinsRepositoryProvider)
        .fetchJobDetail(jobUrl);
    return result.fold((job) => job, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();

  /// P5-08: optimistically flips the last build's `result` to `ABORTED`
  /// right after a cancel request succeeds, ahead of the next poll
  /// reconciling with the server's real state.
  void applyOptimisticCancel() {
    final current = state.value;
    if (current?.lastBuild == null) return;
    state = AsyncData(
      JenkinsJob(
        name: current!.name,
        url: current.url,
        description: current.description,
        color: current.color,
        jobs: current.jobs,
        lastBuild: JenkinsBuild(
          number: current.lastBuild!.number,
          url: current.lastBuild!.url,
          result: 'ABORTED',
          timestamp: current.lastBuild!.timestamp,
          duration: current.lastBuild!.duration,
          estimatedDuration: current.lastBuild!.estimatedDuration,
          building: false,
          displayName: current.lastBuild!.displayName,
        ),
        healthReport: current.healthReport,
        property: current.property,
        builds: current.builds,
      ),
    );
  }
}
