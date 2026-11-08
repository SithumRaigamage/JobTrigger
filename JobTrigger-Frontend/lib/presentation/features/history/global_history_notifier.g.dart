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
        retry: noRetry,
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
    r'c0fb3ce86adf10ccce72c6cbfc0b745ed85e74e4';

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

/// P14-09: the result filter chips on Global History
/// (`UI-UX/screens/08-global-history`).

@ProviderFor(GlobalHistoryFilterNotifier)
final globalHistoryFilterNotifierProvider =
    GlobalHistoryFilterNotifierProvider._();

/// P14-09: the result filter chips on Global History
/// (`UI-UX/screens/08-global-history`).
final class GlobalHistoryFilterNotifierProvider
    extends
        $NotifierProvider<GlobalHistoryFilterNotifier, HistoryResultFilter> {
  /// P14-09: the result filter chips on Global History
  /// (`UI-UX/screens/08-global-history`).
  GlobalHistoryFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalHistoryFilterNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalHistoryFilterNotifierHash();

  @$internal
  @override
  GlobalHistoryFilterNotifier create() => GlobalHistoryFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HistoryResultFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HistoryResultFilter>(value),
    );
  }
}

String _$globalHistoryFilterNotifierHash() =>
    r'3cb1eecc1ded9530d3aca63e7a890ebd6b1ef8a2';

/// P14-09: the result filter chips on Global History
/// (`UI-UX/screens/08-global-history`).

abstract class _$GlobalHistoryFilterNotifier
    extends $Notifier<HistoryResultFilter> {
  HistoryResultFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<HistoryResultFilter, HistoryResultFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HistoryResultFilter, HistoryResultFilter>,
              HistoryResultFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The timeline with the chosen filter applied, split into day sections.

@ProviderFor(filteredGlobalHistory)
final filteredGlobalHistoryProvider = FilteredGlobalHistoryProvider._();

/// The timeline with the chosen filter applied, split into day sections.

final class FilteredGlobalHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<(DateTime, List<HistoryEntry>)>>,
          AsyncValue<List<(DateTime, List<HistoryEntry>)>>,
          AsyncValue<List<(DateTime, List<HistoryEntry>)>>
        >
    with $Provider<AsyncValue<List<(DateTime, List<HistoryEntry>)>>> {
  /// The timeline with the chosen filter applied, split into day sections.
  FilteredGlobalHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredGlobalHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredGlobalHistoryHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<(DateTime, List<HistoryEntry>)>>>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AsyncValue<List<(DateTime, List<HistoryEntry>)>> create(Ref ref) {
    return filteredGlobalHistory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    AsyncValue<List<(DateTime, List<HistoryEntry>)>> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<(DateTime, List<HistoryEntry>)>>>(
            value,
          ),
    );
  }
}

String _$filteredGlobalHistoryHash() =>
    r'111fd52ac6faad1c3c91e60f6bb4113438b0c03c';
