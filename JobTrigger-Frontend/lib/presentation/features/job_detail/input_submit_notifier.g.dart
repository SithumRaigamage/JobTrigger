// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_submit_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-PIPE-05. Family-keyed by build URL. Approves/rejects a paused input
/// step — see `JenkinsRepository.submitInput`'s doc comment for the
/// (unverified) endpoint mechanics. Same success/error haptic + toast
/// shape as `TriggerBuildNotifier`/`CancelBuildNotifier`, plus refreshing
/// both `JobDetailNotifier` (the pipeline may have resumed/finished) and
/// `PendingInputNotifier` (this input is resolved either way) on success.

@ProviderFor(InputSubmitNotifier)
final inputSubmitNotifierProvider = InputSubmitNotifierFamily._();

/// US-PIPE-05. Family-keyed by build URL. Approves/rejects a paused input
/// step — see `JenkinsRepository.submitInput`'s doc comment for the
/// (unverified) endpoint mechanics. Same success/error haptic + toast
/// shape as `TriggerBuildNotifier`/`CancelBuildNotifier`, plus refreshing
/// both `JobDetailNotifier` (the pipeline may have resumed/finished) and
/// `PendingInputNotifier` (this input is resolved either way) on success.
final class InputSubmitNotifierProvider
    extends $AsyncNotifierProvider<InputSubmitNotifier, void> {
  /// US-PIPE-05. Family-keyed by build URL. Approves/rejects a paused input
  /// step — see `JenkinsRepository.submitInput`'s doc comment for the
  /// (unverified) endpoint mechanics. Same success/error haptic + toast
  /// shape as `TriggerBuildNotifier`/`CancelBuildNotifier`, plus refreshing
  /// both `JobDetailNotifier` (the pipeline may have resumed/finished) and
  /// `PendingInputNotifier` (this input is resolved either way) on success.
  InputSubmitNotifierProvider._({
    required InputSubmitNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inputSubmitNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inputSubmitNotifierHash();

  @override
  String toString() {
    return r'inputSubmitNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  InputSubmitNotifier create() => InputSubmitNotifier();

  @override
  bool operator ==(Object other) {
    return other is InputSubmitNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inputSubmitNotifierHash() =>
    r'be3c20746d5de94f0af43c10beced6bc482d57db';

/// US-PIPE-05. Family-keyed by build URL. Approves/rejects a paused input
/// step — see `JenkinsRepository.submitInput`'s doc comment for the
/// (unverified) endpoint mechanics. Same success/error haptic + toast
/// shape as `TriggerBuildNotifier`/`CancelBuildNotifier`, plus refreshing
/// both `JobDetailNotifier` (the pipeline may have resumed/finished) and
/// `PendingInputNotifier` (this input is resolved either way) on success.

final class InputSubmitNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          InputSubmitNotifier,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  InputSubmitNotifierFamily._()
    : super(
        retry: null,
        name: r'inputSubmitNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-PIPE-05. Family-keyed by build URL. Approves/rejects a paused input
  /// step — see `JenkinsRepository.submitInput`'s doc comment for the
  /// (unverified) endpoint mechanics. Same success/error haptic + toast
  /// shape as `TriggerBuildNotifier`/`CancelBuildNotifier`, plus refreshing
  /// both `JobDetailNotifier` (the pipeline may have resumed/finished) and
  /// `PendingInputNotifier` (this input is resolved either way) on success.

  InputSubmitNotifierProvider call(String buildUrl) =>
      InputSubmitNotifierProvider._(argument: buildUrl, from: this);

  @override
  String toString() => r'inputSubmitNotifierProvider';
}

/// US-PIPE-05. Family-keyed by build URL. Approves/rejects a paused input
/// step — see `JenkinsRepository.submitInput`'s doc comment for the
/// (unverified) endpoint mechanics. Same success/error haptic + toast
/// shape as `TriggerBuildNotifier`/`CancelBuildNotifier`, plus refreshing
/// both `JobDetailNotifier` (the pipeline may have resumed/finished) and
/// `PendingInputNotifier` (this input is resolved either way) on success.

abstract class _$InputSubmitNotifier extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as String;
  String get buildUrl => _$args;

  FutureOr<void> build(String buildUrl);
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
