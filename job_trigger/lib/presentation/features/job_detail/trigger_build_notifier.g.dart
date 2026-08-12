// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trigger_build_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Family-keyed by the job's URL. On success, refreshes `JobDetailNotifier`
/// and shows a success toast — matching `JobDetailViewModel.triggerBuild`
/// (Swift). P6-04: the old app's `UINotificationFeedbackGenerator`
/// `.success`/`.error` calls (`HomeViewModel.swift:97/107`,
/// `JobDetailViewModel.swift:147/203`) don't have a Flutter equivalent
/// pair, so `mediumImpact`/`heavyImpact` stand in as a distinguishable
/// success/error pair.

@ProviderFor(TriggerBuildNotifier)
final triggerBuildNotifierProvider = TriggerBuildNotifierFamily._();

/// Family-keyed by the job's URL. On success, refreshes `JobDetailNotifier`
/// and shows a success toast — matching `JobDetailViewModel.triggerBuild`
/// (Swift). P6-04: the old app's `UINotificationFeedbackGenerator`
/// `.success`/`.error` calls (`HomeViewModel.swift:97/107`,
/// `JobDetailViewModel.swift:147/203`) don't have a Flutter equivalent
/// pair, so `mediumImpact`/`heavyImpact` stand in as a distinguishable
/// success/error pair.
final class TriggerBuildNotifierProvider
    extends $AsyncNotifierProvider<TriggerBuildNotifier, void> {
  /// Family-keyed by the job's URL. On success, refreshes `JobDetailNotifier`
  /// and shows a success toast — matching `JobDetailViewModel.triggerBuild`
  /// (Swift). P6-04: the old app's `UINotificationFeedbackGenerator`
  /// `.success`/`.error` calls (`HomeViewModel.swift:97/107`,
  /// `JobDetailViewModel.swift:147/203`) don't have a Flutter equivalent
  /// pair, so `mediumImpact`/`heavyImpact` stand in as a distinguishable
  /// success/error pair.
  TriggerBuildNotifierProvider._({
    required TriggerBuildNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'triggerBuildNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$triggerBuildNotifierHash();

  @override
  String toString() {
    return r'triggerBuildNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TriggerBuildNotifier create() => TriggerBuildNotifier();

  @override
  bool operator ==(Object other) {
    return other is TriggerBuildNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$triggerBuildNotifierHash() =>
    r'6893ff03c2cf93b08bd6507695d3859d20ca2299';

/// Family-keyed by the job's URL. On success, refreshes `JobDetailNotifier`
/// and shows a success toast — matching `JobDetailViewModel.triggerBuild`
/// (Swift). P6-04: the old app's `UINotificationFeedbackGenerator`
/// `.success`/`.error` calls (`HomeViewModel.swift:97/107`,
/// `JobDetailViewModel.swift:147/203`) don't have a Flutter equivalent
/// pair, so `mediumImpact`/`heavyImpact` stand in as a distinguishable
/// success/error pair.

final class TriggerBuildNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TriggerBuildNotifier,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  TriggerBuildNotifierFamily._()
    : super(
        retry: null,
        name: r'triggerBuildNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family-keyed by the job's URL. On success, refreshes `JobDetailNotifier`
  /// and shows a success toast — matching `JobDetailViewModel.triggerBuild`
  /// (Swift). P6-04: the old app's `UINotificationFeedbackGenerator`
  /// `.success`/`.error` calls (`HomeViewModel.swift:97/107`,
  /// `JobDetailViewModel.swift:147/203`) don't have a Flutter equivalent
  /// pair, so `mediumImpact`/`heavyImpact` stand in as a distinguishable
  /// success/error pair.

  TriggerBuildNotifierProvider call(String jobUrl) =>
      TriggerBuildNotifierProvider._(argument: jobUrl, from: this);

  @override
  String toString() => r'triggerBuildNotifierProvider';
}

/// Family-keyed by the job's URL. On success, refreshes `JobDetailNotifier`
/// and shows a success toast — matching `JobDetailViewModel.triggerBuild`
/// (Swift). P6-04: the old app's `UINotificationFeedbackGenerator`
/// `.success`/`.error` calls (`HomeViewModel.swift:97/107`,
/// `JobDetailViewModel.swift:147/203`) don't have a Flutter equivalent
/// pair, so `mediumImpact`/`heavyImpact` stand in as a distinguishable
/// success/error pair.

abstract class _$TriggerBuildNotifier extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as String;
  String get jobUrl => _$args;

  FutureOr<void> build(String jobUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
