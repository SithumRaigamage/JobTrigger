// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage_steps_notifiers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-JX-04: the steps of one stage (or parallel branch). `null` means the
/// server has no Pipeline REST API for it, so the UI offers the full
/// console instead.

@ProviderFor(stageSteps)
final stageStepsProvider = StageStepsFamily._();

/// US-JX-04: the steps of one stage (or parallel branch). `null` means the
/// server has no Pipeline REST API for it, so the UI offers the full
/// console instead.

final class StageStepsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PipelineStep>?>,
          List<PipelineStep>?,
          FutureOr<List<PipelineStep>?>
        >
    with
        $FutureModifier<List<PipelineStep>?>,
        $FutureProvider<List<PipelineStep>?> {
  /// US-JX-04: the steps of one stage (or parallel branch). `null` means the
  /// server has no Pipeline REST API for it, so the UI offers the full
  /// console instead.
  StageStepsProvider._({
    required StageStepsFamily super.from,
    required (String, String, {bool live}) super.argument,
  }) : super(
         retry: null,
         name: r'stageStepsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stageStepsHash();

  @override
  String toString() {
    return r'stageStepsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PipelineStep>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PipelineStep>?> create(Ref ref) {
    final argument = this.argument as (String, String, {bool live});
    return stageSteps(ref, argument.$1, argument.$2, live: argument.live);
  }

  @override
  bool operator ==(Object other) {
    return other is StageStepsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stageStepsHash() => r'60644ae47518b57d77acee7897d8b045d5e21eb1';

/// US-JX-04: the steps of one stage (or parallel branch). `null` means the
/// server has no Pipeline REST API for it, so the UI offers the full
/// console instead.

final class StageStepsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PipelineStep>?>,
          (String, String, {bool live})
        > {
  StageStepsFamily._()
    : super(
        retry: null,
        name: r'stageStepsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-JX-04: the steps of one stage (or parallel branch). `null` means the
  /// server has no Pipeline REST API for it, so the UI offers the full
  /// console instead.

  StageStepsProvider call(
    String buildUrl,
    String stageId, {
    bool live = false,
  }) => StageStepsProvider._(
    argument: (buildUrl, stageId, live: live),
    from: this,
  );

  @override
  String toString() => r'stageStepsProvider';
}

/// US-JX-04: one step's log, live-updating while the step runs.

@ProviderFor(stepLog)
final stepLogProvider = StepLogFamily._();

/// US-JX-04: one step's log, live-updating while the step runs.

final class StepLogProvider
    extends $FunctionalProvider<AsyncValue<StepLog>, StepLog, FutureOr<StepLog>>
    with $FutureModifier<StepLog>, $FutureProvider<StepLog> {
  /// US-JX-04: one step's log, live-updating while the step runs.
  StepLogProvider._({
    required StepLogFamily super.from,
    required (String, String, {bool live}) super.argument,
  }) : super(
         retry: null,
         name: r'stepLogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stepLogHash();

  @override
  String toString() {
    return r'stepLogProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<StepLog> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<StepLog> create(Ref ref) {
    final argument = this.argument as (String, String, {bool live});
    return stepLog(ref, argument.$1, argument.$2, live: argument.live);
  }

  @override
  bool operator ==(Object other) {
    return other is StepLogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stepLogHash() => r'fafef38d688550d397b5c817a3e9088c97983762';

/// US-JX-04: one step's log, live-updating while the step runs.

final class StepLogFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<StepLog>,
          (String, String, {bool live})
        > {
  StepLogFamily._()
    : super(
        retry: null,
        name: r'stepLogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-JX-04: one step's log, live-updating while the step runs.

  StepLogProvider call(String buildUrl, String stepId, {bool live = false}) =>
      StepLogProvider._(argument: (buildUrl, stepId, live: live), from: this);

  @override
  String toString() => r'stepLogProvider';
}
