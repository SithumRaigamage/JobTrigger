// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pipeline_stages_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(PipelineStagesNotifier)
final pipelineStagesNotifierProvider = PipelineStagesNotifierFamily._();

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
final class PipelineStagesNotifierProvider
    extends
        $AsyncNotifierProvider<PipelineStagesNotifier, List<PipelineStage>?> {
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
  PipelineStagesNotifierProvider._({
    required PipelineStagesNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pipelineStagesNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pipelineStagesNotifierHash();

  @override
  String toString() {
    return r'pipelineStagesNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PipelineStagesNotifier create() => PipelineStagesNotifier();

  @override
  bool operator ==(Object other) {
    return other is PipelineStagesNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pipelineStagesNotifierHash() =>
    r'59ff7596cb508e7ce6573b5332be4796f15baf54';

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

final class PipelineStagesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PipelineStagesNotifier,
          AsyncValue<List<PipelineStage>?>,
          List<PipelineStage>?,
          FutureOr<List<PipelineStage>?>,
          String
        > {
  PipelineStagesNotifierFamily._()
    : super(
        retry: null,
        name: r'pipelineStagesNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

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

  PipelineStagesNotifierProvider call(String buildUrl) =>
      PipelineStagesNotifierProvider._(argument: buildUrl, from: this);

  @override
  String toString() => r'pipelineStagesNotifierProvider';
}

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

abstract class _$PipelineStagesNotifier
    extends $AsyncNotifier<List<PipelineStage>?> {
  late final _$args = ref.$arg as String;
  String get buildUrl => _$args;

  FutureOr<List<PipelineStage>?> build(String buildUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<PipelineStage>?>, List<PipelineStage>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<PipelineStage>?>,
                List<PipelineStage>?
              >,
              AsyncValue<List<PipelineStage>?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
