// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_job_log_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One-shot fetch of a completed job's log (`US-GH-LOG-01`), keyed by
/// `(owner, repo, jobId)`. There is no polling: a refresh is the user's
/// explicit "check again", since GitHub offers no safe way to tail a log.

@ProviderFor(GitHubJobLogNotifier)
final gitHubJobLogNotifierProvider = GitHubJobLogNotifierFamily._();

/// One-shot fetch of a completed job's log (`US-GH-LOG-01`), keyed by
/// `(owner, repo, jobId)`. There is no polling: a refresh is the user's
/// explicit "check again", since GitHub offers no safe way to tail a log.
final class GitHubJobLogNotifierProvider
    extends $AsyncNotifierProvider<GitHubJobLogNotifier, GitHubJobLog> {
  /// One-shot fetch of a completed job's log (`US-GH-LOG-01`), keyed by
  /// `(owner, repo, jobId)`. There is no polling: a refresh is the user's
  /// explicit "check again", since GitHub offers no safe way to tail a log.
  GitHubJobLogNotifierProvider._({
    required GitHubJobLogNotifierFamily super.from,
    required (String, String, int) super.argument,
  }) : super(
         retry: null,
         name: r'gitHubJobLogNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gitHubJobLogNotifierHash();

  @override
  String toString() {
    return r'gitHubJobLogNotifierProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GitHubJobLogNotifier create() => GitHubJobLogNotifier();

  @override
  bool operator ==(Object other) {
    return other is GitHubJobLogNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitHubJobLogNotifierHash() =>
    r'cb319551bb26b426126fd6eb79cc9e0cff4e33b7';

/// One-shot fetch of a completed job's log (`US-GH-LOG-01`), keyed by
/// `(owner, repo, jobId)`. There is no polling: a refresh is the user's
/// explicit "check again", since GitHub offers no safe way to tail a log.

final class GitHubJobLogNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GitHubJobLogNotifier,
          AsyncValue<GitHubJobLog>,
          GitHubJobLog,
          FutureOr<GitHubJobLog>,
          (String, String, int)
        > {
  GitHubJobLogNotifierFamily._()
    : super(
        retry: null,
        name: r'gitHubJobLogNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One-shot fetch of a completed job's log (`US-GH-LOG-01`), keyed by
  /// `(owner, repo, jobId)`. There is no polling: a refresh is the user's
  /// explicit "check again", since GitHub offers no safe way to tail a log.

  GitHubJobLogNotifierProvider call(String owner, String repo, int jobId) =>
      GitHubJobLogNotifierProvider._(
        argument: (owner, repo, jobId),
        from: this,
      );

  @override
  String toString() => r'gitHubJobLogNotifierProvider';
}

/// One-shot fetch of a completed job's log (`US-GH-LOG-01`), keyed by
/// `(owner, repo, jobId)`. There is no polling: a refresh is the user's
/// explicit "check again", since GitHub offers no safe way to tail a log.

abstract class _$GitHubJobLogNotifier extends $AsyncNotifier<GitHubJobLog> {
  late final _$args = ref.$arg as (String, String, int);
  String get owner => _$args.$1;
  String get repo => _$args.$2;
  int get jobId => _$args.$3;

  FutureOr<GitHubJobLog> build(String owner, String repo, int jobId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GitHubJobLog>, GitHubJobLog>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GitHubJobLog>, GitHubJobLog>,
              AsyncValue<GitHubJobLog>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2, _$args.$3));
  }
}
