// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_status_polling_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Side-effect-only notifier: while the job's `lastBuild.building == true`,
/// invalidates `JobDetailNotifier` every 5s
/// (`docs/api-reference.md#polling-intervals`), stopping automatically once
/// the build finishes. Timer is always cancelled in `ref.onDispose` — the
/// #1 leak risk per the original migration notes, per this task's own
/// warning.
///
/// `JobDetailScreen` keeps this alive by watching it; it has no state of
/// its own worth reading.

@ProviderFor(BuildStatusPollingNotifier)
final buildStatusPollingNotifierProvider = BuildStatusPollingNotifierFamily._();

/// Side-effect-only notifier: while the job's `lastBuild.building == true`,
/// invalidates `JobDetailNotifier` every 5s
/// (`docs/api-reference.md#polling-intervals`), stopping automatically once
/// the build finishes. Timer is always cancelled in `ref.onDispose` — the
/// #1 leak risk per the original migration notes, per this task's own
/// warning.
///
/// `JobDetailScreen` keeps this alive by watching it; it has no state of
/// its own worth reading.
final class BuildStatusPollingNotifierProvider
    extends $NotifierProvider<BuildStatusPollingNotifier, void> {
  /// Side-effect-only notifier: while the job's `lastBuild.building == true`,
  /// invalidates `JobDetailNotifier` every 5s
  /// (`docs/api-reference.md#polling-intervals`), stopping automatically once
  /// the build finishes. Timer is always cancelled in `ref.onDispose` — the
  /// #1 leak risk per the original migration notes, per this task's own
  /// warning.
  ///
  /// `JobDetailScreen` keeps this alive by watching it; it has no state of
  /// its own worth reading.
  BuildStatusPollingNotifierProvider._({
    required BuildStatusPollingNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'buildStatusPollingNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$buildStatusPollingNotifierHash();

  @override
  String toString() {
    return r'buildStatusPollingNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BuildStatusPollingNotifier create() => BuildStatusPollingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BuildStatusPollingNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$buildStatusPollingNotifierHash() =>
    r'1810657157e4d8eff96d0712333cc234c2e65843';

/// Side-effect-only notifier: while the job's `lastBuild.building == true`,
/// invalidates `JobDetailNotifier` every 5s
/// (`docs/api-reference.md#polling-intervals`), stopping automatically once
/// the build finishes. Timer is always cancelled in `ref.onDispose` — the
/// #1 leak risk per the original migration notes, per this task's own
/// warning.
///
/// `JobDetailScreen` keeps this alive by watching it; it has no state of
/// its own worth reading.

final class BuildStatusPollingNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BuildStatusPollingNotifier,
          void,
          void,
          void,
          String
        > {
  BuildStatusPollingNotifierFamily._()
    : super(
        retry: null,
        name: r'buildStatusPollingNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Side-effect-only notifier: while the job's `lastBuild.building == true`,
  /// invalidates `JobDetailNotifier` every 5s
  /// (`docs/api-reference.md#polling-intervals`), stopping automatically once
  /// the build finishes. Timer is always cancelled in `ref.onDispose` — the
  /// #1 leak risk per the original migration notes, per this task's own
  /// warning.
  ///
  /// `JobDetailScreen` keeps this alive by watching it; it has no state of
  /// its own worth reading.

  BuildStatusPollingNotifierProvider call(String jobUrl) =>
      BuildStatusPollingNotifierProvider._(argument: jobUrl, from: this);

  @override
  String toString() => r'buildStatusPollingNotifierProvider';
}

/// Side-effect-only notifier: while the job's `lastBuild.building == true`,
/// invalidates `JobDetailNotifier` every 5s
/// (`docs/api-reference.md#polling-intervals`), stopping automatically once
/// the build finishes. Timer is always cancelled in `ref.onDispose` — the
/// #1 leak risk per the original migration notes, per this task's own
/// warning.
///
/// `JobDetailScreen` keeps this alive by watching it; it has no state of
/// its own worth reading.

abstract class _$BuildStatusPollingNotifier extends $Notifier<void> {
  late final _$args = ref.$arg as String;
  String get jobUrl => _$args;

  void build(String jobUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
