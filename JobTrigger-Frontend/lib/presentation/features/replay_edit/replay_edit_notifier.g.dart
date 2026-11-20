// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'replay_edit_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-JX-16 AC2/AC3/AC5: the starting script for [jobUrl]. Held in memory
/// only; never cached or logged.

@ProviderFor(replayScript)
final replayScriptProvider = ReplayScriptFamily._();

/// US-JX-16 AC2/AC3/AC5: the starting script for [jobUrl]. Held in memory
/// only; never cached or logged.

final class ReplayScriptProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReplayScript>,
          ReplayScript,
          FutureOr<ReplayScript>
        >
    with $FutureModifier<ReplayScript>, $FutureProvider<ReplayScript> {
  /// US-JX-16 AC2/AC3/AC5: the starting script for [jobUrl]. Held in memory
  /// only; never cached or logged.
  ReplayScriptProvider._({
    required ReplayScriptFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'replayScriptProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$replayScriptHash();

  @override
  String toString() {
    return r'replayScriptProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ReplayScript> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReplayScript> create(Ref ref) {
    final argument = this.argument as String;
    return replayScript(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReplayScriptProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$replayScriptHash() => r'edd87b583fcef5cd280f0c594486c339634fa013';

/// US-JX-16 AC2/AC3/AC5: the starting script for [jobUrl]. Held in memory
/// only; never cached or logged.

final class ReplayScriptFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ReplayScript>, String> {
  ReplayScriptFamily._()
    : super(
        retry: null,
        name: r'replayScriptProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-JX-16 AC2/AC3/AC5: the starting script for [jobUrl]. Held in memory
  /// only; never cached or logged.

  ReplayScriptProvider call(String jobUrl) =>
      ReplayScriptProvider._(argument: jobUrl, from: this);

  @override
  String toString() => r'replayScriptProvider';
}

@ProviderFor(replayPolling)
final replayPollingProvider = ReplayPollingProvider._();

final class ReplayPollingProvider
    extends $FunctionalProvider<ReplayPolling, ReplayPolling, ReplayPolling>
    with $Provider<ReplayPolling> {
  ReplayPollingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'replayPollingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$replayPollingHash();

  @$internal
  @override
  $ProviderElement<ReplayPolling> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReplayPolling create(Ref ref) {
    return replayPolling(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReplayPolling value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReplayPolling>(value),
    );
  }
}

String _$replayPollingHash() => r'c83c1d55416dd3f84c07a2472bac623949225026';

/// US-JX-16 AC6–AC8: submits the edited script and finds the new build.
/// Family-keyed by the replayed build's URL.

@ProviderFor(ReplayEditNotifier)
final replayEditNotifierProvider = ReplayEditNotifierFamily._();

/// US-JX-16 AC6–AC8: submits the edited script and finds the new build.
/// Family-keyed by the replayed build's URL.
final class ReplayEditNotifierProvider
    extends $AsyncNotifierProvider<ReplayEditNotifier, void> {
  /// US-JX-16 AC6–AC8: submits the edited script and finds the new build.
  /// Family-keyed by the replayed build's URL.
  ReplayEditNotifierProvider._({
    required ReplayEditNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'replayEditNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$replayEditNotifierHash();

  @override
  String toString() {
    return r'replayEditNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ReplayEditNotifier create() => ReplayEditNotifier();

  @override
  bool operator ==(Object other) {
    return other is ReplayEditNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$replayEditNotifierHash() =>
    r'f816c51c14e1dbe692ad0b8a367554eed9a3762d';

/// US-JX-16 AC6–AC8: submits the edited script and finds the new build.
/// Family-keyed by the replayed build's URL.

final class ReplayEditNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ReplayEditNotifier,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  ReplayEditNotifierFamily._()
    : super(
        retry: null,
        name: r'replayEditNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-JX-16 AC6–AC8: submits the edited script and finds the new build.
  /// Family-keyed by the replayed build's URL.

  ReplayEditNotifierProvider call(String buildUrl) =>
      ReplayEditNotifierProvider._(argument: buildUrl, from: this);

  @override
  String toString() => r'replayEditNotifierProvider';
}

/// US-JX-16 AC6–AC8: submits the edited script and finds the new build.
/// Family-keyed by the replayed build's URL.

abstract class _$ReplayEditNotifier extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as String;
  String get buildUrl => _$args;

  FutureOr<void> build(String buildUrl);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
