// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_history_pages_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-JX-06: job history, [historyPageSize] builds at a time, all the way
/// back. The first page loads with the screen; [loadMore] appends the next.
/// (`JobHistoryNotifier` stays as the simple first-page source for the Run
/// parameter picker.)

@ProviderFor(JobHistoryPagesNotifier)
final jobHistoryPagesNotifierProvider = JobHistoryPagesNotifierFamily._();

/// US-JX-06: job history, [historyPageSize] builds at a time, all the way
/// back. The first page loads with the screen; [loadMore] appends the next.
/// (`JobHistoryNotifier` stays as the simple first-page source for the Run
/// parameter picker.)
final class JobHistoryPagesNotifierProvider
    extends $AsyncNotifierProvider<JobHistoryPagesNotifier, HistoryPages> {
  /// US-JX-06: job history, [historyPageSize] builds at a time, all the way
  /// back. The first page loads with the screen; [loadMore] appends the next.
  /// (`JobHistoryNotifier` stays as the simple first-page source for the Run
  /// parameter picker.)
  JobHistoryPagesNotifierProvider._({
    required JobHistoryPagesNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'jobHistoryPagesNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$jobHistoryPagesNotifierHash();

  @override
  String toString() {
    return r'jobHistoryPagesNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  JobHistoryPagesNotifier create() => JobHistoryPagesNotifier();

  @override
  bool operator ==(Object other) {
    return other is JobHistoryPagesNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$jobHistoryPagesNotifierHash() =>
    r'db60b7d9d6e17f4f112f3e52a42830b28f84f573';

/// US-JX-06: job history, [historyPageSize] builds at a time, all the way
/// back. The first page loads with the screen; [loadMore] appends the next.
/// (`JobHistoryNotifier` stays as the simple first-page source for the Run
/// parameter picker.)

final class JobHistoryPagesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          JobHistoryPagesNotifier,
          AsyncValue<HistoryPages>,
          HistoryPages,
          FutureOr<HistoryPages>,
          String
        > {
  JobHistoryPagesNotifierFamily._()
    : super(
        retry: null,
        name: r'jobHistoryPagesNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-JX-06: job history, [historyPageSize] builds at a time, all the way
  /// back. The first page loads with the screen; [loadMore] appends the next.
  /// (`JobHistoryNotifier` stays as the simple first-page source for the Run
  /// parameter picker.)

  JobHistoryPagesNotifierProvider call(String jobUrl) =>
      JobHistoryPagesNotifierProvider._(argument: jobUrl, from: this);

  @override
  String toString() => r'jobHistoryPagesNotifierProvider';
}

/// US-JX-06: job history, [historyPageSize] builds at a time, all the way
/// back. The first page loads with the screen; [loadMore] appends the next.
/// (`JobHistoryNotifier` stays as the simple first-page source for the Run
/// parameter picker.)

abstract class _$JobHistoryPagesNotifier extends $AsyncNotifier<HistoryPages> {
  late final _$args = ref.$arg as String;
  String get jobUrl => _$args;

  FutureOr<HistoryPages> build(String jobUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HistoryPages>, HistoryPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HistoryPages>, HistoryPages>,
              AsyncValue<HistoryPages>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// US-JX-06: the history screen's filter chips, per job.

@ProviderFor(JobHistoryFilterNotifier)
final jobHistoryFilterNotifierProvider = JobHistoryFilterNotifierFamily._();

/// US-JX-06: the history screen's filter chips, per job.
final class JobHistoryFilterNotifierProvider
    extends $NotifierProvider<JobHistoryFilterNotifier, HistoryFilter> {
  /// US-JX-06: the history screen's filter chips, per job.
  JobHistoryFilterNotifierProvider._({
    required JobHistoryFilterNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'jobHistoryFilterNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$jobHistoryFilterNotifierHash();

  @override
  String toString() {
    return r'jobHistoryFilterNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  JobHistoryFilterNotifier create() => JobHistoryFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryFilter>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is JobHistoryFilterNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$jobHistoryFilterNotifierHash() =>
    r'2e6931d04a732c981a423ac352a3e660d9734ec0';

/// US-JX-06: the history screen's filter chips, per job.

final class JobHistoryFilterNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          JobHistoryFilterNotifier,
          HistoryFilter,
          HistoryFilter,
          HistoryFilter,
          String
        > {
  JobHistoryFilterNotifierFamily._()
    : super(
        retry: null,
        name: r'jobHistoryFilterNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-JX-06: the history screen's filter chips, per job.

  JobHistoryFilterNotifierProvider call(String jobUrl) =>
      JobHistoryFilterNotifierProvider._(argument: jobUrl, from: this);

  @override
  String toString() => r'jobHistoryFilterNotifierProvider';
}

/// US-JX-06: the history screen's filter chips, per job.

abstract class _$JobHistoryFilterNotifier extends $Notifier<HistoryFilter> {
  late final _$args = ref.$arg as String;
  String get jobUrl => _$args;

  HistoryFilter build(String jobUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<HistoryFilter, HistoryFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HistoryFilter, HistoryFilter>,
              HistoryFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
