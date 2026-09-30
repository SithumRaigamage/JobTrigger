import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/pipeline_stage.dart';

part 'stage_steps_notifiers.g.dart';

/// How often a running stage's steps, or a running step's log, refresh
/// while its sheet is open.
const _liveRefresh = Duration(seconds: 2);

/// Re-runs the provider on [_liveRefresh] while [live], cancelled with it.
void _refreshWhileLive(Ref ref, bool live) {
  if (!live) return;
  final timer = Timer(_liveRefresh, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
}

/// US-JX-04: the steps of one stage (or parallel branch). `null` means the
/// server has no Pipeline REST API for it, so the UI offers the full
/// console instead.
@riverpod
Future<List<PipelineStep>?> stageSteps(
  Ref ref,
  String buildUrl,
  String stageId, {
  bool live = false,
}) async {
  _refreshWhileLive(ref, live);
  final result = await ref
      .watch(jenkinsRepositoryProvider)
      .fetchStageSteps(buildUrl, stageId);
  return result.fold((steps) => steps, (failure) => throw failure);
}

/// US-JX-04: one step's log, live-updating while the step runs.
@riverpod
Future<StepLog> stepLog(
  Ref ref,
  String buildUrl,
  String stepId, {
  bool live = false,
}) async {
  _refreshWhileLive(ref, live);
  final result = await ref
      .watch(jenkinsRepositoryProvider)
      .fetchStepLog(buildUrl, stepId);
  return result.fold((log) => log, (failure) => throw failure);
}
