import 'dart:async';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../common_widgets/toast_controller.dart';
import '../settings/active_server_notifier.dart';
import 'job_detail_notifier.dart';

part 'trigger_build_notifier.g.dart';

/// Family-keyed by the job's URL. On success, refreshes `JobDetailNotifier`
/// and shows a success toast — matching `JobDetailViewModel.triggerBuild`
/// (Swift). P6-04: the old app's `UINotificationFeedbackGenerator`
/// `.success`/`.error` calls (`HomeViewModel.swift:97/107`,
/// `JobDetailViewModel.swift:147/203`) don't have a Flutter equivalent
/// pair, so `mediumImpact`/`heavyImpact` stand in as a distinguishable
/// success/error pair.
@riverpod
class TriggerBuildNotifier extends _$TriggerBuildNotifier {
  @override
  FutureOr<void> build(String jobUrl) {}

  Future<void> trigger({
    required JenkinsJob job,
    Map<String, String> parameters = const {},
  }) async {
    state = const AsyncLoading();
    final paramToken = ref.read(activeServerNotifierProvider)?.paramToken;

    final result = await ref
        .read(jenkinsRepositoryProvider)
        .triggerBuild(
          jobUrl,
          isParameterized: job.isParameterized,
          parameters: parameters,
          paramToken: paramToken,
        );

    switch (result) {
      case Ok():
        await ref.read(jobDetailNotifierProvider(jobUrl).notifier).refresh();
        state = const AsyncData(null);
        unawaited(HapticFeedback.mediumImpact());
        ref
            .read(toastControllerProvider)
            .show(
              type: ToastType.success,
              title: 'Build Triggered',
              message: 'A new build for ${job.name} has been requested.',
            );
      case Err(:final error):
        state = AsyncError(error, StackTrace.current);
        unawaited(HapticFeedback.heavyImpact());
        ref
            .read(toastControllerProvider)
            .show(
              type: ToastType.error,
              title: 'Trigger Failed',
              message: error.message,
            );
    }
  }
}
