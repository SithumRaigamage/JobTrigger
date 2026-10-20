// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_enabled_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-JX-13: enables or disables a job, then refreshes its detail so the
/// badge and Trigger button follow the server's real state.

@ProviderFor(JobEnabledNotifier)
final jobEnabledNotifierProvider = JobEnabledNotifierFamily._();

/// US-JX-13: enables or disables a job, then refreshes its detail so the
/// badge and Trigger button follow the server's real state.
final class JobEnabledNotifierProvider
    extends $AsyncNotifierProvider<JobEnabledNotifier, void> {
  /// US-JX-13: enables or disables a job, then refreshes its detail so the
  /// badge and Trigger button follow the server's real state.
  JobEnabledNotifierProvider._({
    required JobEnabledNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'jobEnabledNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$jobEnabledNotifierHash();

  @override
  String toString() {
    return r'jobEnabledNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  JobEnabledNotifier create() => JobEnabledNotifier();

  @override
  bool operator ==(Object other) {
    return other is JobEnabledNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$jobEnabledNotifierHash() =>
    r'90934e1bcb67eb5aaf7b78f67678d1e2f991a891';

/// US-JX-13: enables or disables a job, then refreshes its detail so the
/// badge and Trigger button follow the server's real state.

final class JobEnabledNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          JobEnabledNotifier,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  JobEnabledNotifierFamily._()
    : super(
        retry: null,
        name: r'jobEnabledNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-JX-13: enables or disables a job, then refreshes its detail so the
  /// badge and Trigger button follow the server's real state.

  JobEnabledNotifierProvider call(String jobUrl) =>
      JobEnabledNotifierProvider._(argument: jobUrl, from: this);

  @override
  String toString() => r'jobEnabledNotifierProvider';
}

/// US-JX-13: enables or disables a job, then refreshes its detail so the
/// badge and Trigger button follow the server's real state.

abstract class _$JobEnabledNotifier extends $AsyncNotifier<void> {
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
