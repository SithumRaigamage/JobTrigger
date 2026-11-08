// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_run_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One run's current state (`US-GH-RUN-03`), keyed by `(owner, repo,
/// runId)`. [GitHubRunPollingNotifier] invalidates it every 5s while the
/// run is active, so the screen updates without a manual refresh.

@ProviderFor(GitHubRunNotifier)
final gitHubRunNotifierProvider = GitHubRunNotifierFamily._();

/// One run's current state (`US-GH-RUN-03`), keyed by `(owner, repo,
/// runId)`. [GitHubRunPollingNotifier] invalidates it every 5s while the
/// run is active, so the screen updates without a manual refresh.
final class GitHubRunNotifierProvider
    extends $AsyncNotifierProvider<GitHubRunNotifier, GitHubWorkflowRun> {
  /// One run's current state (`US-GH-RUN-03`), keyed by `(owner, repo,
  /// runId)`. [GitHubRunPollingNotifier] invalidates it every 5s while the
  /// run is active, so the screen updates without a manual refresh.
  GitHubRunNotifierProvider._({
    required GitHubRunNotifierFamily super.from,
    required (String, String, int) super.argument,
  }) : super(
         retry: null,
         name: r'gitHubRunNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gitHubRunNotifierHash();

  @override
  String toString() {
    return r'gitHubRunNotifierProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GitHubRunNotifier create() => GitHubRunNotifier();

  @override
  bool operator ==(Object other) {
    return other is GitHubRunNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitHubRunNotifierHash() => r'3b87940f05f9bf88babef8289a5245c064b4e11f';

/// One run's current state (`US-GH-RUN-03`), keyed by `(owner, repo,
/// runId)`. [GitHubRunPollingNotifier] invalidates it every 5s while the
/// run is active, so the screen updates without a manual refresh.

final class GitHubRunNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GitHubRunNotifier,
          AsyncValue<GitHubWorkflowRun>,
          GitHubWorkflowRun,
          FutureOr<GitHubWorkflowRun>,
          (String, String, int)
        > {
  GitHubRunNotifierFamily._()
    : super(
        retry: null,
        name: r'gitHubRunNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One run's current state (`US-GH-RUN-03`), keyed by `(owner, repo,
  /// runId)`. [GitHubRunPollingNotifier] invalidates it every 5s while the
  /// run is active, so the screen updates without a manual refresh.

  GitHubRunNotifierProvider call(String owner, String repo, int runId) =>
      GitHubRunNotifierProvider._(argument: (owner, repo, runId), from: this);

  @override
  String toString() => r'gitHubRunNotifierProvider';
}

/// One run's current state (`US-GH-RUN-03`), keyed by `(owner, repo,
/// runId)`. [GitHubRunPollingNotifier] invalidates it every 5s while the
/// run is active, so the screen updates without a manual refresh.

abstract class _$GitHubRunNotifier extends $AsyncNotifier<GitHubWorkflowRun> {
  late final _$args = ref.$arg as (String, String, int);
  String get owner => _$args.$1;
  String get repo => _$args.$2;
  int get runId => _$args.$3;

  FutureOr<GitHubWorkflowRun> build(String owner, String repo, int runId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<GitHubWorkflowRun>, GitHubWorkflowRun>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GitHubWorkflowRun>, GitHubWorkflowRun>,
              AsyncValue<GitHubWorkflowRun>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2, _$args.$3));
  }
}
