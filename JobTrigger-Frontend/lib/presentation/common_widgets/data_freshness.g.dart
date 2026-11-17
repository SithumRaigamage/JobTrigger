// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_freshness.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-screen freshness, keyed by a stable string so independent screens
/// don't overwrite each other ("Updated 2m ago" must mean that screen).

@ProviderFor(DataFreshnessNotifier)
final dataFreshnessNotifierProvider = DataFreshnessNotifierFamily._();

/// Per-screen freshness, keyed by a stable string so independent screens
/// don't overwrite each other ("Updated 2m ago" must mean that screen).
final class DataFreshnessNotifierProvider
    extends $NotifierProvider<DataFreshnessNotifier, FreshnessState> {
  /// Per-screen freshness, keyed by a stable string so independent screens
  /// don't overwrite each other ("Updated 2m ago" must mean that screen).
  DataFreshnessNotifierProvider._({
    required DataFreshnessNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'dataFreshnessNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dataFreshnessNotifierHash();

  @override
  String toString() {
    return r'dataFreshnessNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DataFreshnessNotifier create() => DataFreshnessNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FreshnessState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FreshnessState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DataFreshnessNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dataFreshnessNotifierHash() =>
    r'9e150dd3f3c5746d834978e4cecd5272f4ba15ec';

/// Per-screen freshness, keyed by a stable string so independent screens
/// don't overwrite each other ("Updated 2m ago" must mean that screen).

final class DataFreshnessNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DataFreshnessNotifier,
          FreshnessState,
          FreshnessState,
          FreshnessState,
          String
        > {
  DataFreshnessNotifierFamily._()
    : super(
        retry: null,
        name: r'dataFreshnessNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-screen freshness, keyed by a stable string so independent screens
  /// don't overwrite each other ("Updated 2m ago" must mean that screen).

  DataFreshnessNotifierProvider call(String key) =>
      DataFreshnessNotifierProvider._(argument: key, from: this);

  @override
  String toString() => r'dataFreshnessNotifierProvider';
}

/// Per-screen freshness, keyed by a stable string so independent screens
/// don't overwrite each other ("Updated 2m ago" must mean that screen).

abstract class _$DataFreshnessNotifier extends $Notifier<FreshnessState> {
  late final _$args = ref.$arg as String;
  String get key => _$args;

  FreshnessState build(String key);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FreshnessState, FreshnessState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FreshnessState, FreshnessState>,
              FreshnessState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
