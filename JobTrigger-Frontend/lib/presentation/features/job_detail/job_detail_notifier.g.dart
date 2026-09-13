// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_detail_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches one job's detail (params, health, last build) — family-keyed by
/// the job's absolute URL. Standard shape from `docs/architecture.md §4`.

@ProviderFor(JobDetailNotifier)
final jobDetailNotifierProvider = JobDetailNotifierFamily._();

/// Fetches one job's detail (params, health, last build) — family-keyed by
/// the job's absolute URL. Standard shape from `docs/architecture.md §4`.
final class JobDetailNotifierProvider
    extends $AsyncNotifierProvider<JobDetailNotifier, JenkinsJob> {
  /// Fetches one job's detail (params, health, last build) — family-keyed by
  /// the job's absolute URL. Standard shape from `docs/architecture.md §4`.
  JobDetailNotifierProvider._({
    required JobDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'jobDetailNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$jobDetailNotifierHash();

  @override
  String toString() {
    return r'jobDetailNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  JobDetailNotifier create() => JobDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is JobDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$jobDetailNotifierHash() => r'097ce56d6d7ea3d700f95aca8f8948e8b600f403';

/// Fetches one job's detail (params, health, last build) — family-keyed by
/// the job's absolute URL. Standard shape from `docs/architecture.md §4`.

final class JobDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          JobDetailNotifier,
          AsyncValue<JenkinsJob>,
          JenkinsJob,
          FutureOr<JenkinsJob>,
          String
        > {
  JobDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'jobDetailNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches one job's detail (params, health, last build) — family-keyed by
  /// the job's absolute URL. Standard shape from `docs/architecture.md §4`.

  JobDetailNotifierProvider call(String jobUrl) =>
      JobDetailNotifierProvider._(argument: jobUrl, from: this);

  @override
  String toString() => r'jobDetailNotifierProvider';
}

/// Fetches one job's detail (params, health, last build) — family-keyed by
/// the job's absolute URL. Standard shape from `docs/architecture.md §4`.

abstract class _$JobDetailNotifier extends $AsyncNotifier<JenkinsJob> {
  late final _$args = ref.$arg as String;
  String get jobUrl => _$args;

  FutureOr<JenkinsJob> build(String jobUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<JenkinsJob>, JenkinsJob>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<JenkinsJob>, JenkinsJob>,
              AsyncValue<JenkinsJob>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
