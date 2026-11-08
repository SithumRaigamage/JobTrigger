// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_cancel_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cancels a run (`US-GH-RUN-04`). State is `true` once a cancel has been
/// *requested*. Unlike Jenkins there is no optimistic flip to cancelled:
/// GitHub's 202 means the cancel is queued, so the screen shows
/// "Cancelling…" until polling sees the run's real `conclusion`.

@ProviderFor(GitHubCancelNotifier)
final gitHubCancelNotifierProvider = GitHubCancelNotifierFamily._();

/// Cancels a run (`US-GH-RUN-04`). State is `true` once a cancel has been
/// *requested*. Unlike Jenkins there is no optimistic flip to cancelled:
/// GitHub's 202 means the cancel is queued, so the screen shows
/// "Cancelling…" until polling sees the run's real `conclusion`.
final class GitHubCancelNotifierProvider
    extends $AsyncNotifierProvider<GitHubCancelNotifier, bool> {
  /// Cancels a run (`US-GH-RUN-04`). State is `true` once a cancel has been
  /// *requested*. Unlike Jenkins there is no optimistic flip to cancelled:
  /// GitHub's 202 means the cancel is queued, so the screen shows
  /// "Cancelling…" until polling sees the run's real `conclusion`.
  GitHubCancelNotifierProvider._({
    required GitHubCancelNotifierFamily super.from,
    required (String, String, int) super.argument,
  }) : super(
         retry: null,
         name: r'gitHubCancelNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gitHubCancelNotifierHash();

  @override
  String toString() {
    return r'gitHubCancelNotifierProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GitHubCancelNotifier create() => GitHubCancelNotifier();

  @override
  bool operator ==(Object other) {
    return other is GitHubCancelNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitHubCancelNotifierHash() =>
    r'2c8712de7e426d5f973bc3c6abeb368fa6a26bc6';

/// Cancels a run (`US-GH-RUN-04`). State is `true` once a cancel has been
/// *requested*. Unlike Jenkins there is no optimistic flip to cancelled:
/// GitHub's 202 means the cancel is queued, so the screen shows
/// "Cancelling…" until polling sees the run's real `conclusion`.

final class GitHubCancelNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GitHubCancelNotifier,
          AsyncValue<bool>,
          bool,
          FutureOr<bool>,
          (String, String, int)
        > {
  GitHubCancelNotifierFamily._()
    : super(
        retry: null,
        name: r'gitHubCancelNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Cancels a run (`US-GH-RUN-04`). State is `true` once a cancel has been
  /// *requested*. Unlike Jenkins there is no optimistic flip to cancelled:
  /// GitHub's 202 means the cancel is queued, so the screen shows
  /// "Cancelling…" until polling sees the run's real `conclusion`.

  GitHubCancelNotifierProvider call(String owner, String repo, int runId) =>
      GitHubCancelNotifierProvider._(
        argument: (owner, repo, runId),
        from: this,
      );

  @override
  String toString() => r'gitHubCancelNotifierProvider';
}

/// Cancels a run (`US-GH-RUN-04`). State is `true` once a cancel has been
/// *requested*. Unlike Jenkins there is no optimistic flip to cancelled:
/// GitHub's 202 means the cancel is queued, so the screen shows
/// "Cancelling…" until polling sees the run's real `conclusion`.

abstract class _$GitHubCancelNotifier extends $AsyncNotifier<bool> {
  late final _$args = ref.$arg as (String, String, int);
  String get owner => _$args.$1;
  String get repo => _$args.$2;
  int get runId => _$args.$3;

  FutureOr<bool> build(String owner, String repo, int runId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2, _$args.$3));
  }
}
