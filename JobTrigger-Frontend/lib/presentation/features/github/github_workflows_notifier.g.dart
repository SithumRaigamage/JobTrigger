// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_workflows_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches a single repo's workflows (`US-GH-REPO-02`), keyed by
/// `(owner, repo)` — a family provider since `GitHubWorkflowListScreen`
/// can be pushed for any repo in the active credential's list.

@ProviderFor(GitHubWorkflowsNotifier)
final gitHubWorkflowsNotifierProvider = GitHubWorkflowsNotifierFamily._();

/// Fetches a single repo's workflows (`US-GH-REPO-02`), keyed by
/// `(owner, repo)` — a family provider since `GitHubWorkflowListScreen`
/// can be pushed for any repo in the active credential's list.
final class GitHubWorkflowsNotifierProvider
    extends
        $AsyncNotifierProvider<GitHubWorkflowsNotifier, List<GitHubWorkflow>> {
  /// Fetches a single repo's workflows (`US-GH-REPO-02`), keyed by
  /// `(owner, repo)` — a family provider since `GitHubWorkflowListScreen`
  /// can be pushed for any repo in the active credential's list.
  GitHubWorkflowsNotifierProvider._({
    required GitHubWorkflowsNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'gitHubWorkflowsNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gitHubWorkflowsNotifierHash();

  @override
  String toString() {
    return r'gitHubWorkflowsNotifierProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GitHubWorkflowsNotifier create() => GitHubWorkflowsNotifier();

  @override
  bool operator ==(Object other) {
    return other is GitHubWorkflowsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitHubWorkflowsNotifierHash() =>
    r'ae2cb0fa2bc1a5faa8b34f1253aeedcbe67f5042';

/// Fetches a single repo's workflows (`US-GH-REPO-02`), keyed by
/// `(owner, repo)` — a family provider since `GitHubWorkflowListScreen`
/// can be pushed for any repo in the active credential's list.

final class GitHubWorkflowsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GitHubWorkflowsNotifier,
          AsyncValue<List<GitHubWorkflow>>,
          List<GitHubWorkflow>,
          FutureOr<List<GitHubWorkflow>>,
          (String, String)
        > {
  GitHubWorkflowsNotifierFamily._()
    : super(
        retry: null,
        name: r'gitHubWorkflowsNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches a single repo's workflows (`US-GH-REPO-02`), keyed by
  /// `(owner, repo)` — a family provider since `GitHubWorkflowListScreen`
  /// can be pushed for any repo in the active credential's list.

  GitHubWorkflowsNotifierProvider call(String owner, String repo) =>
      GitHubWorkflowsNotifierProvider._(argument: (owner, repo), from: this);

  @override
  String toString() => r'gitHubWorkflowsNotifierProvider';
}

/// Fetches a single repo's workflows (`US-GH-REPO-02`), keyed by
/// `(owner, repo)` — a family provider since `GitHubWorkflowListScreen`
/// can be pushed for any repo in the active credential's list.

abstract class _$GitHubWorkflowsNotifier
    extends $AsyncNotifier<List<GitHubWorkflow>> {
  late final _$args = ref.$arg as (String, String);
  String get owner => _$args.$1;
  String get repo => _$args.$2;

  FutureOr<List<GitHubWorkflow>> build(String owner, String repo);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<GitHubWorkflow>>, List<GitHubWorkflow>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<GitHubWorkflow>>,
                List<GitHubWorkflow>
              >,
              AsyncValue<List<GitHubWorkflow>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
