// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cancel_build_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// POST `{buildNumber}/stop` + optimistic local flip to `ABORTED`
/// (`JobDetailNotifier.applyOptimisticCancel`), reconciled by the next poll
/// — see `docs/state-management.md`. P6-04: haptic feedback on success/error
/// mirrors `JobDetailViewModel.swift:242/252`'s
/// `UINotificationFeedbackGenerator` calls (see `trigger_build_notifier.dart`
/// for why `mediumImpact`/`heavyImpact` stand in for `.success`/`.error`).

@ProviderFor(CancelBuildNotifier)
final cancelBuildNotifierProvider = CancelBuildNotifierFamily._();

/// POST `{buildNumber}/stop` + optimistic local flip to `ABORTED`
/// (`JobDetailNotifier.applyOptimisticCancel`), reconciled by the next poll
/// — see `docs/state-management.md`. P6-04: haptic feedback on success/error
/// mirrors `JobDetailViewModel.swift:242/252`'s
/// `UINotificationFeedbackGenerator` calls (see `trigger_build_notifier.dart`
/// for why `mediumImpact`/`heavyImpact` stand in for `.success`/`.error`).
final class CancelBuildNotifierProvider
    extends $AsyncNotifierProvider<CancelBuildNotifier, void> {
  /// POST `{buildNumber}/stop` + optimistic local flip to `ABORTED`
  /// (`JobDetailNotifier.applyOptimisticCancel`), reconciled by the next poll
  /// — see `docs/state-management.md`. P6-04: haptic feedback on success/error
  /// mirrors `JobDetailViewModel.swift:242/252`'s
  /// `UINotificationFeedbackGenerator` calls (see `trigger_build_notifier.dart`
  /// for why `mediumImpact`/`heavyImpact` stand in for `.success`/`.error`).
  CancelBuildNotifierProvider._({
    required CancelBuildNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cancelBuildNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cancelBuildNotifierHash();

  @override
  String toString() {
    return r'cancelBuildNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CancelBuildNotifier create() => CancelBuildNotifier();

  @override
  bool operator ==(Object other) {
    return other is CancelBuildNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cancelBuildNotifierHash() =>
    r'bc1041e6dd7918a120186dfa8ec57327b97b7180';

/// POST `{buildNumber}/stop` + optimistic local flip to `ABORTED`
/// (`JobDetailNotifier.applyOptimisticCancel`), reconciled by the next poll
/// — see `docs/state-management.md`. P6-04: haptic feedback on success/error
/// mirrors `JobDetailViewModel.swift:242/252`'s
/// `UINotificationFeedbackGenerator` calls (see `trigger_build_notifier.dart`
/// for why `mediumImpact`/`heavyImpact` stand in for `.success`/`.error`).

final class CancelBuildNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CancelBuildNotifier,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  CancelBuildNotifierFamily._()
    : super(
        retry: null,
        name: r'cancelBuildNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// POST `{buildNumber}/stop` + optimistic local flip to `ABORTED`
  /// (`JobDetailNotifier.applyOptimisticCancel`), reconciled by the next poll
  /// — see `docs/state-management.md`. P6-04: haptic feedback on success/error
  /// mirrors `JobDetailViewModel.swift:242/252`'s
  /// `UINotificationFeedbackGenerator` calls (see `trigger_build_notifier.dart`
  /// for why `mediumImpact`/`heavyImpact` stand in for `.success`/`.error`).

  CancelBuildNotifierProvider call(String jobUrl) =>
      CancelBuildNotifierProvider._(argument: jobUrl, from: this);

  @override
  String toString() => r'cancelBuildNotifierProvider';
}

/// POST `{buildNumber}/stop` + optimistic local flip to `ABORTED`
/// (`JobDetailNotifier.applyOptimisticCancel`), reconciled by the next poll
/// — see `docs/state-management.md`. P6-04: haptic feedback on success/error
/// mirrors `JobDetailViewModel.swift:242/252`'s
/// `UINotificationFeedbackGenerator` calls (see `trigger_build_notifier.dart`
/// for why `mediumImpact`/`heavyImpact` stand in for `.success`/`.error`).

abstract class _$CancelBuildNotifier extends $AsyncNotifier<void> {
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
