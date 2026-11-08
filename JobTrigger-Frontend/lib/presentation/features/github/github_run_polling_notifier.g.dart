// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_run_polling_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Side-effect-only notifier (`US-GH-RUN-03`): while the run isn't
/// `completed`, invalidates [GitHubRunNotifier] every 5s, same cadence and
/// timer discipline as `BuildStatusPollingNotifier` — the timer is always
/// cancelled in `ref.onDispose`.
///
/// Unlike Jenkins, GitHub has an hourly rate limit, so a [RateLimitFailure]
/// stops polling instead of retrying into a worse state; the screen shows
/// the failure's message and the user refreshes by hand once it lifts.
/// Other errors keep polling: the previous value stays visible, so a
/// dropped connection recovers on its own.

@ProviderFor(GitHubRunPollingNotifier)
final gitHubRunPollingNotifierProvider = GitHubRunPollingNotifierFamily._();

/// Side-effect-only notifier (`US-GH-RUN-03`): while the run isn't
/// `completed`, invalidates [GitHubRunNotifier] every 5s, same cadence and
/// timer discipline as `BuildStatusPollingNotifier` — the timer is always
/// cancelled in `ref.onDispose`.
///
/// Unlike Jenkins, GitHub has an hourly rate limit, so a [RateLimitFailure]
/// stops polling instead of retrying into a worse state; the screen shows
/// the failure's message and the user refreshes by hand once it lifts.
/// Other errors keep polling: the previous value stays visible, so a
/// dropped connection recovers on its own.
final class GitHubRunPollingNotifierProvider
    extends $NotifierProvider<GitHubRunPollingNotifier, void> {
  /// Side-effect-only notifier (`US-GH-RUN-03`): while the run isn't
  /// `completed`, invalidates [GitHubRunNotifier] every 5s, same cadence and
  /// timer discipline as `BuildStatusPollingNotifier` — the timer is always
  /// cancelled in `ref.onDispose`.
  ///
  /// Unlike Jenkins, GitHub has an hourly rate limit, so a [RateLimitFailure]
  /// stops polling instead of retrying into a worse state; the screen shows
  /// the failure's message and the user refreshes by hand once it lifts.
  /// Other errors keep polling: the previous value stays visible, so a
  /// dropped connection recovers on its own.
  GitHubRunPollingNotifierProvider._({
    required GitHubRunPollingNotifierFamily super.from,
    required (String, String, int) super.argument,
  }) : super(
         retry: null,
         name: r'gitHubRunPollingNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gitHubRunPollingNotifierHash();

  @override
  String toString() {
    return r'gitHubRunPollingNotifierProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GitHubRunPollingNotifier create() => GitHubRunPollingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GitHubRunPollingNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitHubRunPollingNotifierHash() =>
    r'92b254a981e066ad41eb4ac11adc466a7efca09c';

/// Side-effect-only notifier (`US-GH-RUN-03`): while the run isn't
/// `completed`, invalidates [GitHubRunNotifier] every 5s, same cadence and
/// timer discipline as `BuildStatusPollingNotifier` — the timer is always
/// cancelled in `ref.onDispose`.
///
/// Unlike Jenkins, GitHub has an hourly rate limit, so a [RateLimitFailure]
/// stops polling instead of retrying into a worse state; the screen shows
/// the failure's message and the user refreshes by hand once it lifts.
/// Other errors keep polling: the previous value stays visible, so a
/// dropped connection recovers on its own.

final class GitHubRunPollingNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GitHubRunPollingNotifier,
          void,
          void,
          void,
          (String, String, int)
        > {
  GitHubRunPollingNotifierFamily._()
    : super(
        retry: null,
        name: r'gitHubRunPollingNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Side-effect-only notifier (`US-GH-RUN-03`): while the run isn't
  /// `completed`, invalidates [GitHubRunNotifier] every 5s, same cadence and
  /// timer discipline as `BuildStatusPollingNotifier` — the timer is always
  /// cancelled in `ref.onDispose`.
  ///
  /// Unlike Jenkins, GitHub has an hourly rate limit, so a [RateLimitFailure]
  /// stops polling instead of retrying into a worse state; the screen shows
  /// the failure's message and the user refreshes by hand once it lifts.
  /// Other errors keep polling: the previous value stays visible, so a
  /// dropped connection recovers on its own.

  GitHubRunPollingNotifierProvider call(String owner, String repo, int runId) =>
      GitHubRunPollingNotifierProvider._(
        argument: (owner, repo, runId),
        from: this,
      );

  @override
  String toString() => r'gitHubRunPollingNotifierProvider';
}

/// Side-effect-only notifier (`US-GH-RUN-03`): while the run isn't
/// `completed`, invalidates [GitHubRunNotifier] every 5s, same cadence and
/// timer discipline as `BuildStatusPollingNotifier` — the timer is always
/// cancelled in `ref.onDispose`.
///
/// Unlike Jenkins, GitHub has an hourly rate limit, so a [RateLimitFailure]
/// stops polling instead of retrying into a worse state; the screen shows
/// the failure's message and the user refreshes by hand once it lifts.
/// Other errors keep polling: the previous value stays visible, so a
/// dropped connection recovers on its own.

abstract class _$GitHubRunPollingNotifier extends $Notifier<void> {
  late final _$args = ref.$arg as (String, String, int);
  String get owner => _$args.$1;
  String get repo => _$args.$2;
  int get runId => _$args.$3;

  void build(String owner, String repo, int runId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2, _$args.$3));
  }
}
