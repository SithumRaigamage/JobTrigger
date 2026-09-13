// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_history_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Last 20 builds for one job — family-keyed by the job's URL. Unlike
/// `GlobalHistoryNotifier`, this needs its own fetch
/// (`JenkinsRepository.fetchJobHistory`) since the tree/detail fetches
/// don't carry a job's full `builds[]` list — see `docs/api-reference.md`.

@ProviderFor(JobHistoryNotifier)
final jobHistoryNotifierProvider = JobHistoryNotifierFamily._();

/// Last 20 builds for one job — family-keyed by the job's URL. Unlike
/// `GlobalHistoryNotifier`, this needs its own fetch
/// (`JenkinsRepository.fetchJobHistory`) since the tree/detail fetches
/// don't carry a job's full `builds[]` list — see `docs/api-reference.md`.
final class JobHistoryNotifierProvider
    extends $AsyncNotifierProvider<JobHistoryNotifier, List<JenkinsBuild>> {
  /// Last 20 builds for one job — family-keyed by the job's URL. Unlike
  /// `GlobalHistoryNotifier`, this needs its own fetch
  /// (`JenkinsRepository.fetchJobHistory`) since the tree/detail fetches
  /// don't carry a job's full `builds[]` list — see `docs/api-reference.md`.
  JobHistoryNotifierProvider._({
    required JobHistoryNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'jobHistoryNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$jobHistoryNotifierHash();

  @override
  String toString() {
    return r'jobHistoryNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  JobHistoryNotifier create() => JobHistoryNotifier();

  @override
  bool operator ==(Object other) {
    return other is JobHistoryNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$jobHistoryNotifierHash() =>
    r'd8317e76c30074c47a21ef00595d5d6f89734ceb';

/// Last 20 builds for one job — family-keyed by the job's URL. Unlike
/// `GlobalHistoryNotifier`, this needs its own fetch
/// (`JenkinsRepository.fetchJobHistory`) since the tree/detail fetches
/// don't carry a job's full `builds[]` list — see `docs/api-reference.md`.

final class JobHistoryNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          JobHistoryNotifier,
          AsyncValue<List<JenkinsBuild>>,
          List<JenkinsBuild>,
          FutureOr<List<JenkinsBuild>>,
          String
        > {
  JobHistoryNotifierFamily._()
    : super(
        retry: null,
        name: r'jobHistoryNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Last 20 builds for one job — family-keyed by the job's URL. Unlike
  /// `GlobalHistoryNotifier`, this needs its own fetch
  /// (`JenkinsRepository.fetchJobHistory`) since the tree/detail fetches
  /// don't carry a job's full `builds[]` list — see `docs/api-reference.md`.

  JobHistoryNotifierProvider call(String jobUrl) =>
      JobHistoryNotifierProvider._(argument: jobUrl, from: this);

  @override
  String toString() => r'jobHistoryNotifierProvider';
}

/// Last 20 builds for one job — family-keyed by the job's URL. Unlike
/// `GlobalHistoryNotifier`, this needs its own fetch
/// (`JenkinsRepository.fetchJobHistory`) since the tree/detail fetches
/// don't carry a job's full `builds[]` list — see `docs/api-reference.md`.

abstract class _$JobHistoryNotifier extends $AsyncNotifier<List<JenkinsBuild>> {
  late final _$args = ref.$arg as String;
  String get jobUrl => _$args;

  FutureOr<List<JenkinsBuild>> build(String jobUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<JenkinsBuild>>, List<JenkinsBuild>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<JenkinsBuild>>, List<JenkinsBuild>>,
              AsyncValue<List<JenkinsBuild>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
