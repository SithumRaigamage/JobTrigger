import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/github_repository_impl.dart';
import '../../../domain/github/github_job.dart';

part 'github_jobs_notifier.g.dart';

/// A run's jobs and their steps (`US-GH-RUN-05`), keyed by `(owner, repo,
/// runId)`. [GitHubRunPollingNotifier] refreshes it on the same 5s tick as
/// the run, so steps tick over while the run is active.
@riverpod
class GitHubJobsNotifier extends _$GitHubJobsNotifier {
  @override
  Future<List<GitHubJob>> build(String owner, String repo, int runId) async {
    final result = await ref
        .watch(gitHubRepositoryProvider)
        .fetchJobs(owner, repo, runId);
    return result.fold((jobs) => jobs, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
