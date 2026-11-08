// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_jobs_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A run's jobs and their steps (`US-GH-RUN-05`), keyed by `(owner, repo,
/// runId)`. [GitHubRunPollingNotifier] refreshes it on the same 5s tick as
/// the run, so steps tick over while the run is active.

@ProviderFor(GitHubJobsNotifier)
final gitHubJobsNotifierProvider = GitHubJobsNotifierFamily._();

/// A run's jobs and their steps (`US-GH-RUN-05`), keyed by `(owner, repo,
/// runId)`. [GitHubRunPollingNotifier] refreshes it on the same 5s tick as
/// the run, so steps tick over while the run is active.
final class GitHubJobsNotifierProvider
    extends $AsyncNotifierProvider<GitHubJobsNotifier, List<GitHubJob>> {
  /// A run's jobs and their steps (`US-GH-RUN-05`), keyed by `(owner, repo,
  /// runId)`. [GitHubRunPollingNotifier] refreshes it on the same 5s tick as
  /// the run, so steps tick over while the run is active.
  GitHubJobsNotifierProvider._({
    required GitHubJobsNotifierFamily super.from,
    required (String, String, int) super.argument,
  }) : super(
         retry: null,
         name: r'gitHubJobsNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gitHubJobsNotifierHash();

  @override
  String toString() {
    return r'gitHubJobsNotifierProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GitHubJobsNotifier create() => GitHubJobsNotifier();

  @override
  bool operator ==(Object other) {
    return other is GitHubJobsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitHubJobsNotifierHash() =>
    r'fec58b113800c5baa1534ba2f1e658b50f393c1e';

/// A run's jobs and their steps (`US-GH-RUN-05`), keyed by `(owner, repo,
/// runId)`. [GitHubRunPollingNotifier] refreshes it on the same 5s tick as
/// the run, so steps tick over while the run is active.

final class GitHubJobsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GitHubJobsNotifier,
          AsyncValue<List<GitHubJob>>,
          List<GitHubJob>,
          FutureOr<List<GitHubJob>>,
          (String, String, int)
        > {
  GitHubJobsNotifierFamily._()
    : super(
        retry: null,
        name: r'gitHubJobsNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A run's jobs and their steps (`US-GH-RUN-05`), keyed by `(owner, repo,
  /// runId)`. [GitHubRunPollingNotifier] refreshes it on the same 5s tick as
  /// the run, so steps tick over while the run is active.

  GitHubJobsNotifierProvider call(String owner, String repo, int runId) =>
      GitHubJobsNotifierProvider._(argument: (owner, repo, runId), from: this);

  @override
  String toString() => r'gitHubJobsNotifierProvider';
}

/// A run's jobs and their steps (`US-GH-RUN-05`), keyed by `(owner, repo,
/// runId)`. [GitHubRunPollingNotifier] refreshes it on the same 5s tick as
/// the run, so steps tick over while the run is active.

abstract class _$GitHubJobsNotifier extends $AsyncNotifier<List<GitHubJob>> {
  late final _$args = ref.$arg as (String, String, int);
  String get owner => _$args.$1;
  String get repo => _$args.$2;
  int get runId => _$args.$3;

  FutureOr<List<GitHubJob>> build(String owner, String repo, int runId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<GitHubJob>>, List<GitHubJob>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<GitHubJob>>, List<GitHubJob>>,
              AsyncValue<List<GitHubJob>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2, _$args.$3));
  }
}
