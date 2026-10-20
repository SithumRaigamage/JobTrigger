// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pinned_jobs_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pins for the active server, in the order they were pinned. Rebuilt
/// (and reloaded) whenever the active server changes: pins belong to a
/// server, not the app.

@ProviderFor(PinnedJobsNotifier)
final pinnedJobsNotifierProvider = PinnedJobsNotifierProvider._();

/// Pins for the active server, in the order they were pinned. Rebuilt
/// (and reloaded) whenever the active server changes: pins belong to a
/// server, not the app.
final class PinnedJobsNotifierProvider
    extends $NotifierProvider<PinnedJobsNotifier, List<PinnedJob>> {
  /// Pins for the active server, in the order they were pinned. Rebuilt
  /// (and reloaded) whenever the active server changes: pins belong to a
  /// server, not the app.
  PinnedJobsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinnedJobsNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinnedJobsNotifierHash();

  @$internal
  @override
  PinnedJobsNotifier create() => PinnedJobsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PinnedJob> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PinnedJob>>(value),
    );
  }
}

String _$pinnedJobsNotifierHash() =>
    r'2bc64aef795dc160015bebeaf83b872602d6e918';

/// Pins for the active server, in the order they were pinned. Rebuilt
/// (and reloaded) whenever the active server changes: pins belong to a
/// server, not the app.

abstract class _$PinnedJobsNotifier extends $Notifier<List<PinnedJob>> {
  List<PinnedJob> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<PinnedJob>, List<PinnedJob>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<PinnedJob>, List<PinnedJob>>,
              List<PinnedJob>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// A pinned job's live status: the job, or null when it no longer exists
/// (404), so Home can offer to remove the stale pin.

@ProviderFor(pinnedJobStatus)
final pinnedJobStatusProvider = PinnedJobStatusFamily._();

/// A pinned job's live status: the job, or null when it no longer exists
/// (404), so Home can offer to remove the stale pin.

final class PinnedJobStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<JenkinsJob?>,
          JenkinsJob?,
          FutureOr<JenkinsJob?>
        >
    with $FutureModifier<JenkinsJob?>, $FutureProvider<JenkinsJob?> {
  /// A pinned job's live status: the job, or null when it no longer exists
  /// (404), so Home can offer to remove the stale pin.
  PinnedJobStatusProvider._({
    required PinnedJobStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pinnedJobStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pinnedJobStatusHash();

  @override
  String toString() {
    return r'pinnedJobStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<JenkinsJob?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<JenkinsJob?> create(Ref ref) {
    final argument = this.argument as String;
    return pinnedJobStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PinnedJobStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pinnedJobStatusHash() => r'506215841b9eead4be40ccf7b61a6a3ee0e43b17';

/// A pinned job's live status: the job, or null when it no longer exists
/// (404), so Home can offer to remove the stale pin.

final class PinnedJobStatusFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<JenkinsJob?>, String> {
  PinnedJobStatusFamily._()
    : super(
        retry: null,
        name: r'pinnedJobStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A pinned job's live status: the job, or null when it no longer exists
  /// (404), so Home can offer to remove the stale pin.

  PinnedJobStatusProvider call(String url) =>
      PinnedJobStatusProvider._(argument: url, from: this);

  @override
  String toString() => r'pinnedJobStatusProvider';
}
