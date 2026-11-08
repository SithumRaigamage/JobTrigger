// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-JX-09: the server-wide build queue, refreshed every [_refreshEvery]
/// while the queue screen is open. The timer is cancelled on dispose.

@ProviderFor(QueueNotifier)
final queueNotifierProvider = QueueNotifierProvider._();

/// US-JX-09: the server-wide build queue, refreshed every [_refreshEvery]
/// while the queue screen is open. The timer is cancelled on dispose.
final class QueueNotifierProvider
    extends $AsyncNotifierProvider<QueueNotifier, List<QueueEntry>> {
  /// US-JX-09: the server-wide build queue, refreshed every [_refreshEvery]
  /// while the queue screen is open. The timer is cancelled on dispose.
  QueueNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: noRetry,
        name: r'queueNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$queueNotifierHash();

  @$internal
  @override
  QueueNotifier create() => QueueNotifier();
}

String _$queueNotifierHash() => r'44eaa9e03d213c6ce25600b0939a315bb332410e';

/// US-JX-09: the server-wide build queue, refreshed every [_refreshEvery]
/// while the queue screen is open. The timer is cancelled on dispose.

abstract class _$QueueNotifier extends $AsyncNotifier<List<QueueEntry>> {
  FutureOr<List<QueueEntry>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<QueueEntry>>, List<QueueEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<QueueEntry>>, List<QueueEntry>>,
              AsyncValue<List<QueueEntry>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
