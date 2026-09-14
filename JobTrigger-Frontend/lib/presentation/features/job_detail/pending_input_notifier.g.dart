// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_input_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-PIPE-05. Family-keyed by build URL — its own fetch, separate from
/// `JobDetailNotifier`, same shape as `TestReportNotifier`/
/// `PipelineStagesNotifier`. `null` data means nothing is currently
/// paused, a normal state, not an error. Kept live-updating while a build
/// runs via `BuildStatusPollingNotifier`'s existing 5s tick, same
/// reasoning as `PipelineStagesNotifier`.

@ProviderFor(PendingInputNotifier)
final pendingInputNotifierProvider = PendingInputNotifierFamily._();

/// US-PIPE-05. Family-keyed by build URL — its own fetch, separate from
/// `JobDetailNotifier`, same shape as `TestReportNotifier`/
/// `PipelineStagesNotifier`. `null` data means nothing is currently
/// paused, a normal state, not an error. Kept live-updating while a build
/// runs via `BuildStatusPollingNotifier`'s existing 5s tick, same
/// reasoning as `PipelineStagesNotifier`.
final class PendingInputNotifierProvider
    extends $AsyncNotifierProvider<PendingInputNotifier, PendingInput?> {
  /// US-PIPE-05. Family-keyed by build URL — its own fetch, separate from
  /// `JobDetailNotifier`, same shape as `TestReportNotifier`/
  /// `PipelineStagesNotifier`. `null` data means nothing is currently
  /// paused, a normal state, not an error. Kept live-updating while a build
  /// runs via `BuildStatusPollingNotifier`'s existing 5s tick, same
  /// reasoning as `PipelineStagesNotifier`.
  PendingInputNotifierProvider._({
    required PendingInputNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pendingInputNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingInputNotifierHash();

  @override
  String toString() {
    return r'pendingInputNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PendingInputNotifier create() => PendingInputNotifier();

  @override
  bool operator ==(Object other) {
    return other is PendingInputNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingInputNotifierHash() =>
    r'5c60f4a10b8126f5d9a6f19cd1b7d0034769b233';

/// US-PIPE-05. Family-keyed by build URL — its own fetch, separate from
/// `JobDetailNotifier`, same shape as `TestReportNotifier`/
/// `PipelineStagesNotifier`. `null` data means nothing is currently
/// paused, a normal state, not an error. Kept live-updating while a build
/// runs via `BuildStatusPollingNotifier`'s existing 5s tick, same
/// reasoning as `PipelineStagesNotifier`.

final class PendingInputNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PendingInputNotifier,
          AsyncValue<PendingInput?>,
          PendingInput?,
          FutureOr<PendingInput?>,
          String
        > {
  PendingInputNotifierFamily._()
    : super(
        retry: null,
        name: r'pendingInputNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-PIPE-05. Family-keyed by build URL — its own fetch, separate from
  /// `JobDetailNotifier`, same shape as `TestReportNotifier`/
  /// `PipelineStagesNotifier`. `null` data means nothing is currently
  /// paused, a normal state, not an error. Kept live-updating while a build
  /// runs via `BuildStatusPollingNotifier`'s existing 5s tick, same
  /// reasoning as `PipelineStagesNotifier`.

  PendingInputNotifierProvider call(String buildUrl) =>
      PendingInputNotifierProvider._(argument: buildUrl, from: this);

  @override
  String toString() => r'pendingInputNotifierProvider';
}

/// US-PIPE-05. Family-keyed by build URL — its own fetch, separate from
/// `JobDetailNotifier`, same shape as `TestReportNotifier`/
/// `PipelineStagesNotifier`. `null` data means nothing is currently
/// paused, a normal state, not an error. Kept live-updating while a build
/// runs via `BuildStatusPollingNotifier`'s existing 5s tick, same
/// reasoning as `PipelineStagesNotifier`.

abstract class _$PendingInputNotifier extends $AsyncNotifier<PendingInput?> {
  late final _$args = ref.$arg as String;
  String get buildUrl => _$args;

  FutureOr<PendingInput?> build(String buildUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PendingInput?>, PendingInput?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PendingInput?>, PendingInput?>,
              AsyncValue<PendingInput?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
