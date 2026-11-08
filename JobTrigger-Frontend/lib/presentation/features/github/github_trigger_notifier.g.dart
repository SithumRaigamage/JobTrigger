// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_trigger_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Dispatches a workflow (`US-GH-RUN-02`), keyed by `(owner, repo,
/// workflowId)`. GitHub's 204 carries no run id, so there is nothing to
/// track: on success the runs list is refreshed now and once more after a
/// short delay, since the new run takes a moment to appear.

@ProviderFor(GitHubTriggerNotifier)
final gitHubTriggerNotifierProvider = GitHubTriggerNotifierFamily._();

/// Dispatches a workflow (`US-GH-RUN-02`), keyed by `(owner, repo,
/// workflowId)`. GitHub's 204 carries no run id, so there is nothing to
/// track: on success the runs list is refreshed now and once more after a
/// short delay, since the new run takes a moment to appear.
final class GitHubTriggerNotifierProvider
    extends $AsyncNotifierProvider<GitHubTriggerNotifier, void> {
  /// Dispatches a workflow (`US-GH-RUN-02`), keyed by `(owner, repo,
  /// workflowId)`. GitHub's 204 carries no run id, so there is nothing to
  /// track: on success the runs list is refreshed now and once more after a
  /// short delay, since the new run takes a moment to appear.
  GitHubTriggerNotifierProvider._({
    required GitHubTriggerNotifierFamily super.from,
    required (String, String, int) super.argument,
  }) : super(
         retry: null,
         name: r'gitHubTriggerNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gitHubTriggerNotifierHash();

  @override
  String toString() {
    return r'gitHubTriggerNotifierProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GitHubTriggerNotifier create() => GitHubTriggerNotifier();

  @override
  bool operator ==(Object other) {
    return other is GitHubTriggerNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitHubTriggerNotifierHash() =>
    r'f5d7ecb2cd8ce354e8c2f224137500cd2f102ece';

/// Dispatches a workflow (`US-GH-RUN-02`), keyed by `(owner, repo,
/// workflowId)`. GitHub's 204 carries no run id, so there is nothing to
/// track: on success the runs list is refreshed now and once more after a
/// short delay, since the new run takes a moment to appear.

final class GitHubTriggerNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GitHubTriggerNotifier,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          (String, String, int)
        > {
  GitHubTriggerNotifierFamily._()
    : super(
        retry: null,
        name: r'gitHubTriggerNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Dispatches a workflow (`US-GH-RUN-02`), keyed by `(owner, repo,
  /// workflowId)`. GitHub's 204 carries no run id, so there is nothing to
  /// track: on success the runs list is refreshed now and once more after a
  /// short delay, since the new run takes a moment to appear.

  GitHubTriggerNotifierProvider call(
    String owner,
    String repo,
    int workflowId,
  ) => GitHubTriggerNotifierProvider._(
    argument: (owner, repo, workflowId),
    from: this,
  );

  @override
  String toString() => r'gitHubTriggerNotifierProvider';
}

/// Dispatches a workflow (`US-GH-RUN-02`), keyed by `(owner, repo,
/// workflowId)`. GitHub's 204 carries no run id, so there is nothing to
/// track: on success the runs list is refreshed now and once more after a
/// short delay, since the new run takes a moment to appear.

abstract class _$GitHubTriggerNotifier extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as (String, String, int);
  String get owner => _$args.$1;
  String get repo => _$args.$2;
  int get workflowId => _$args.$3;

  FutureOr<void> build(String owner, String repo, int workflowId);
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
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2, _$args.$3));
  }
}
