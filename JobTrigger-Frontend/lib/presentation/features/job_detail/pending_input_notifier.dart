import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/pending_input.dart';

part 'pending_input_notifier.g.dart';

/// US-PIPE-05. Family-keyed by build URL — its own fetch, separate from
/// `JobDetailNotifier`, same shape as `TestReportNotifier`/
/// `PipelineStagesNotifier`. `null` data means nothing is currently
/// paused, a normal state, not an error. Kept live-updating while a build
/// runs via `BuildStatusPollingNotifier`'s existing 5s tick, same
/// reasoning as `PipelineStagesNotifier`.
@riverpod
class PendingInputNotifier extends _$PendingInputNotifier {
  @override
  Future<PendingInput?> build(String buildUrl) async {
    final result = await ref
        .watch(jenkinsRepositoryProvider)
        .fetchPendingInput(buildUrl);
    return result.fold((input) => input, (failure) => throw failure);
  }
}
