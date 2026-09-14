// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_status_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-PIPE-01. Family-keyed by job URL. Tracks the queue item a
/// just-triggered build was assigned, started imperatively via [track]
/// (called by `TriggerBuildNotifier` right after a successful trigger
/// returns a queue-item URL) — there's no per-job queue endpoint to poll
/// passively, so this can't be derived reactively the way
/// `BuildStatusPollingNotifier` derives from `JobDetailNotifier`.
///
/// `null` state means "nothing currently tracked": no trigger has
/// happened yet this session, or the tracked item already resolved. Polls
/// every 2s (shorter than `US-JOB-04`'s 5s build-status poll — queue waits
/// are often brief) until the item becomes an executable build or is
/// cancelled, then stops and, if it started building, invalidates
/// `JobDetailNotifier` so the existing building-status flow picks up from
/// there. Only covers builds triggered from this app session — an
/// already-queued build discovered on a cold job-detail load isn't
/// detected (a known, deliberately out-of-scope gap; Jenkins' queue is
/// server-wide with no per-job endpoint to check without scanning
/// everyone's queued items).

@ProviderFor(QueueStatusNotifier)
final queueStatusNotifierProvider = QueueStatusNotifierFamily._();

/// US-PIPE-01. Family-keyed by job URL. Tracks the queue item a
/// just-triggered build was assigned, started imperatively via [track]
/// (called by `TriggerBuildNotifier` right after a successful trigger
/// returns a queue-item URL) — there's no per-job queue endpoint to poll
/// passively, so this can't be derived reactively the way
/// `BuildStatusPollingNotifier` derives from `JobDetailNotifier`.
///
/// `null` state means "nothing currently tracked": no trigger has
/// happened yet this session, or the tracked item already resolved. Polls
/// every 2s (shorter than `US-JOB-04`'s 5s build-status poll — queue waits
/// are often brief) until the item becomes an executable build or is
/// cancelled, then stops and, if it started building, invalidates
/// `JobDetailNotifier` so the existing building-status flow picks up from
/// there. Only covers builds triggered from this app session — an
/// already-queued build discovered on a cold job-detail load isn't
/// detected (a known, deliberately out-of-scope gap; Jenkins' queue is
/// server-wide with no per-job endpoint to check without scanning
/// everyone's queued items).
final class QueueStatusNotifierProvider
    extends $NotifierProvider<QueueStatusNotifier, QueueItem?> {
  /// US-PIPE-01. Family-keyed by job URL. Tracks the queue item a
  /// just-triggered build was assigned, started imperatively via [track]
  /// (called by `TriggerBuildNotifier` right after a successful trigger
  /// returns a queue-item URL) — there's no per-job queue endpoint to poll
  /// passively, so this can't be derived reactively the way
  /// `BuildStatusPollingNotifier` derives from `JobDetailNotifier`.
  ///
  /// `null` state means "nothing currently tracked": no trigger has
  /// happened yet this session, or the tracked item already resolved. Polls
  /// every 2s (shorter than `US-JOB-04`'s 5s build-status poll — queue waits
  /// are often brief) until the item becomes an executable build or is
  /// cancelled, then stops and, if it started building, invalidates
  /// `JobDetailNotifier` so the existing building-status flow picks up from
  /// there. Only covers builds triggered from this app session — an
  /// already-queued build discovered on a cold job-detail load isn't
  /// detected (a known, deliberately out-of-scope gap; Jenkins' queue is
  /// server-wide with no per-job endpoint to check without scanning
  /// everyone's queued items).
  QueueStatusNotifierProvider._({
    required QueueStatusNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'queueStatusNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$queueStatusNotifierHash();

  @override
  String toString() {
    return r'queueStatusNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  QueueStatusNotifier create() => QueueStatusNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QueueItem? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QueueItem?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QueueStatusNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$queueStatusNotifierHash() =>
    r'5696fafddfafc569e8a81c721b57a89c7cbcf1d9';

/// US-PIPE-01. Family-keyed by job URL. Tracks the queue item a
/// just-triggered build was assigned, started imperatively via [track]
/// (called by `TriggerBuildNotifier` right after a successful trigger
/// returns a queue-item URL) — there's no per-job queue endpoint to poll
/// passively, so this can't be derived reactively the way
/// `BuildStatusPollingNotifier` derives from `JobDetailNotifier`.
///
/// `null` state means "nothing currently tracked": no trigger has
/// happened yet this session, or the tracked item already resolved. Polls
/// every 2s (shorter than `US-JOB-04`'s 5s build-status poll — queue waits
/// are often brief) until the item becomes an executable build or is
/// cancelled, then stops and, if it started building, invalidates
/// `JobDetailNotifier` so the existing building-status flow picks up from
/// there. Only covers builds triggered from this app session — an
/// already-queued build discovered on a cold job-detail load isn't
/// detected (a known, deliberately out-of-scope gap; Jenkins' queue is
/// server-wide with no per-job endpoint to check without scanning
/// everyone's queued items).

final class QueueStatusNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          QueueStatusNotifier,
          QueueItem?,
          QueueItem?,
          QueueItem?,
          String
        > {
  QueueStatusNotifierFamily._()
    : super(
        retry: null,
        name: r'queueStatusNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-PIPE-01. Family-keyed by job URL. Tracks the queue item a
  /// just-triggered build was assigned, started imperatively via [track]
  /// (called by `TriggerBuildNotifier` right after a successful trigger
  /// returns a queue-item URL) — there's no per-job queue endpoint to poll
  /// passively, so this can't be derived reactively the way
  /// `BuildStatusPollingNotifier` derives from `JobDetailNotifier`.
  ///
  /// `null` state means "nothing currently tracked": no trigger has
  /// happened yet this session, or the tracked item already resolved. Polls
  /// every 2s (shorter than `US-JOB-04`'s 5s build-status poll — queue waits
  /// are often brief) until the item becomes an executable build or is
  /// cancelled, then stops and, if it started building, invalidates
  /// `JobDetailNotifier` so the existing building-status flow picks up from
  /// there. Only covers builds triggered from this app session — an
  /// already-queued build discovered on a cold job-detail load isn't
  /// detected (a known, deliberately out-of-scope gap; Jenkins' queue is
  /// server-wide with no per-job endpoint to check without scanning
  /// everyone's queued items).

  QueueStatusNotifierProvider call(String jobUrl) =>
      QueueStatusNotifierProvider._(argument: jobUrl, from: this);

  @override
  String toString() => r'queueStatusNotifierProvider';
}

/// US-PIPE-01. Family-keyed by job URL. Tracks the queue item a
/// just-triggered build was assigned, started imperatively via [track]
/// (called by `TriggerBuildNotifier` right after a successful trigger
/// returns a queue-item URL) — there's no per-job queue endpoint to poll
/// passively, so this can't be derived reactively the way
/// `BuildStatusPollingNotifier` derives from `JobDetailNotifier`.
///
/// `null` state means "nothing currently tracked": no trigger has
/// happened yet this session, or the tracked item already resolved. Polls
/// every 2s (shorter than `US-JOB-04`'s 5s build-status poll — queue waits
/// are often brief) until the item becomes an executable build or is
/// cancelled, then stops and, if it started building, invalidates
/// `JobDetailNotifier` so the existing building-status flow picks up from
/// there. Only covers builds triggered from this app session — an
/// already-queued build discovered on a cold job-detail load isn't
/// detected (a known, deliberately out-of-scope gap; Jenkins' queue is
/// server-wide with no per-job endpoint to check without scanning
/// everyone's queued items).

abstract class _$QueueStatusNotifier extends $Notifier<QueueItem?> {
  late final _$args = ref.$arg as String;
  String get jobUrl => _$args;

  QueueItem? build(String jobUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<QueueItem?, QueueItem?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QueueItem?, QueueItem?>,
              QueueItem?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
