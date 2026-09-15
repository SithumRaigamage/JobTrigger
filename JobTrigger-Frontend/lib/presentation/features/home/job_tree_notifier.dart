import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/jenkins_job.dart';

part 'job_tree_notifier.g.dart';

/// Fetches the full job tree from the active server — standard shape from
/// `docs/architecture.md §4`. `refresh()` backs pull-to-refresh on
/// `HomeScreen`.
@riverpod
class JobTreeNotifier extends _$JobTreeNotifier {
  @override
  Future<List<JenkinsJob>> build() async {
    final result = await ref.watch(jenkinsRepositoryProvider).fetchJobTree();
    return result.fold((jobs) => jobs, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
