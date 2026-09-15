import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/jenkins_build.dart';

part 'job_history_notifier.g.dart';

/// Last 20 builds for one job — family-keyed by the job's URL. Unlike
/// `GlobalHistoryNotifier`, this needs its own fetch
/// (`JenkinsRepository.fetchJobHistory`) since the tree/detail fetches
/// don't carry a job's full `builds[]` list — see `docs/api-reference.md`.
@riverpod
class JobHistoryNotifier extends _$JobHistoryNotifier {
  @override
  Future<List<JenkinsBuild>> build(String jobUrl) async {
    final result = await ref
        .watch(jenkinsRepositoryProvider)
        .fetchJobHistory(jobUrl);
    return result.fold((builds) => builds, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
