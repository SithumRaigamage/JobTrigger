// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_runs_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches one workflow's recent runs (`US-GH-RUN-01`), keyed by
/// `(owner, repo, workflowId)` — a family provider since the runs screen
/// can be opened for any workflow of any repo.

@ProviderFor(GitHubRunsNotifier)
final gitHubRunsNotifierProvider = GitHubRunsNotifierFamily._();

/// Fetches one workflow's recent runs (`US-GH-RUN-01`), keyed by
/// `(owner, repo, workflowId)` — a family provider since the runs screen
/// can be opened for any workflow of any repo.
final class GitHubRunsNotifierProvider
    extends
        $AsyncNotifierProvider<GitHubRunsNotifier, List<GitHubWorkflowRun>> {
  /// Fetches one workflow's recent runs (`US-GH-RUN-01`), keyed by
  /// `(owner, repo, workflowId)` — a family provider since the runs screen
  /// can be opened for any workflow of any repo.
  GitHubRunsNotifierProvider._({
    required GitHubRunsNotifierFamily super.from,
    required (String, String, int) super.argument,
  }) : super(
         retry: null,
         name: r'gitHubRunsNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gitHubRunsNotifierHash();

  @override
  String toString() {
    return r'gitHubRunsNotifierProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GitHubRunsNotifier create() => GitHubRunsNotifier();

  @override
  bool operator ==(Object other) {
    return other is GitHubRunsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitHubRunsNotifierHash() =>
    r'4253e40abc6ff5fd3bed876f886572b9b22208f4';

/// Fetches one workflow's recent runs (`US-GH-RUN-01`), keyed by
/// `(owner, repo, workflowId)` — a family provider since the runs screen
/// can be opened for any workflow of any repo.

final class GitHubRunsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GitHubRunsNotifier,
          AsyncValue<List<GitHubWorkflowRun>>,
          List<GitHubWorkflowRun>,
          FutureOr<List<GitHubWorkflowRun>>,
          (String, String, int)
        > {
  GitHubRunsNotifierFamily._()
    : super(
        retry: null,
        name: r'gitHubRunsNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches one workflow's recent runs (`US-GH-RUN-01`), keyed by
  /// `(owner, repo, workflowId)` — a family provider since the runs screen
  /// can be opened for any workflow of any repo.

  GitHubRunsNotifierProvider call(String owner, String repo, int workflowId) =>
      GitHubRunsNotifierProvider._(
        argument: (owner, repo, workflowId),
        from: this,
      );

  @override
  String toString() => r'gitHubRunsNotifierProvider';
}

/// Fetches one workflow's recent runs (`US-GH-RUN-01`), keyed by
/// `(owner, repo, workflowId)` — a family provider since the runs screen
/// can be opened for any workflow of any repo.

abstract class _$GitHubRunsNotifier
    extends $AsyncNotifier<List<GitHubWorkflowRun>> {
  late final _$args = ref.$arg as (String, String, int);
  String get owner => _$args.$1;
  String get repo => _$args.$2;
  int get workflowId => _$args.$3;

  FutureOr<List<GitHubWorkflowRun>> build(
    String owner,
    String repo,
    int workflowId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<GitHubWorkflowRun>>,
              List<GitHubWorkflowRun>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<GitHubWorkflowRun>>,
                List<GitHubWorkflowRun>
              >,
              AsyncValue<List<GitHubWorkflowRun>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2, _$args.$3));
  }
}
