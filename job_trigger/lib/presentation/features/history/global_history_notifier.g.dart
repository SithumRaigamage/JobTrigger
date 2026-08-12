// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_history_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Traverses the already-fetched job tree (`JobTreeNotifier`) to build the
/// cross-job top-50 timeline — no separate fetch, per
/// `docs/state-management.md`.

@ProviderFor(GlobalHistoryNotifier)
final globalHistoryNotifierProvider = GlobalHistoryNotifierProvider._();

/// Traverses the already-fetched job tree (`JobTreeNotifier`) to build the
/// cross-job top-50 timeline — no separate fetch, per
/// `docs/state-management.md`.
final class GlobalHistoryNotifierProvider
    extends $AsyncNotifierProvider<GlobalHistoryNotifier, List<HistoryEntry>> {
  /// Traverses the already-fetched job tree (`JobTreeNotifier`) to build the
  /// cross-job top-50 timeline — no separate fetch, per
  /// `docs/state-management.md`.
  GlobalHistoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalHistoryNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalHistoryNotifierHash();

  @$internal
  @override
  GlobalHistoryNotifier create() => GlobalHistoryNotifier();
}

String _$globalHistoryNotifierHash() =>
    r'741ccd1d6f6aa786263c8774b9d938428c6e1af0';

/// Traverses the already-fetched job tree (`JobTreeNotifier`) to build the
/// cross-job top-50 timeline — no separate fetch, per
/// `docs/state-management.md`.

abstract class _$GlobalHistoryNotifier
    extends $AsyncNotifier<List<HistoryEntry>> {
  FutureOr<List<HistoryEntry>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<HistoryEntry>>, List<HistoryEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<HistoryEntry>>, List<HistoryEntry>>,
              AsyncValue<List<HistoryEntry>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
