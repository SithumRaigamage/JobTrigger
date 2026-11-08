// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_run_history_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A workflow's run history, [gitHubRunsPageSize] runs at a time, newest
/// first (`US-GH-HIST-01`). The first page loads with the screen;
/// [loadMore] appends the next. This is the same call as the runs list,
/// just paged further.

@ProviderFor(GitHubRunHistoryNotifier)
final gitHubRunHistoryNotifierProvider = GitHubRunHistoryNotifierFamily._();

/// A workflow's run history, [gitHubRunsPageSize] runs at a time, newest
/// first (`US-GH-HIST-01`). The first page loads with the screen;
/// [loadMore] appends the next. This is the same call as the runs list,
/// just paged further.
final class GitHubRunHistoryNotifierProvider
    extends $AsyncNotifierProvider<GitHubRunHistoryNotifier, GitHubRunPages> {
  /// A workflow's run history, [gitHubRunsPageSize] runs at a time, newest
  /// first (`US-GH-HIST-01`). The first page loads with the screen;
  /// [loadMore] appends the next. This is the same call as the runs list,
  /// just paged further.
  GitHubRunHistoryNotifierProvider._({
    required GitHubRunHistoryNotifierFamily super.from,
    required (String, String, int) super.argument,
  }) : super(
         retry: null,
         name: r'gitHubRunHistoryNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gitHubRunHistoryNotifierHash();

  @override
  String toString() {
    return r'gitHubRunHistoryNotifierProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GitHubRunHistoryNotifier create() => GitHubRunHistoryNotifier();

  @override
  bool operator ==(Object other) {
    return other is GitHubRunHistoryNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitHubRunHistoryNotifierHash() =>
    r'df44c9ba1ec233f16fbbfa18ba8e52f08dccddf1';

/// A workflow's run history, [gitHubRunsPageSize] runs at a time, newest
/// first (`US-GH-HIST-01`). The first page loads with the screen;
/// [loadMore] appends the next. This is the same call as the runs list,
/// just paged further.

final class GitHubRunHistoryNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GitHubRunHistoryNotifier,
          AsyncValue<GitHubRunPages>,
          GitHubRunPages,
          FutureOr<GitHubRunPages>,
          (String, String, int)
        > {
  GitHubRunHistoryNotifierFamily._()
    : super(
        retry: null,
        name: r'gitHubRunHistoryNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A workflow's run history, [gitHubRunsPageSize] runs at a time, newest
  /// first (`US-GH-HIST-01`). The first page loads with the screen;
  /// [loadMore] appends the next. This is the same call as the runs list,
  /// just paged further.

  GitHubRunHistoryNotifierProvider call(
    String owner,
    String repo,
    int workflowId,
  ) => GitHubRunHistoryNotifierProvider._(
    argument: (owner, repo, workflowId),
    from: this,
  );

  @override
  String toString() => r'gitHubRunHistoryNotifierProvider';
}

/// A workflow's run history, [gitHubRunsPageSize] runs at a time, newest
/// first (`US-GH-HIST-01`). The first page loads with the screen;
/// [loadMore] appends the next. This is the same call as the runs list,
/// just paged further.

abstract class _$GitHubRunHistoryNotifier
    extends $AsyncNotifier<GitHubRunPages> {
  late final _$args = ref.$arg as (String, String, int);
  String get owner => _$args.$1;
  String get repo => _$args.$2;
  int get workflowId => _$args.$3;

  FutureOr<GitHubRunPages> build(String owner, String repo, int workflowId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GitHubRunPages>, GitHubRunPages>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GitHubRunPages>, GitHubRunPages>,
              AsyncValue<GitHubRunPages>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2, _$args.$3));
  }
}
