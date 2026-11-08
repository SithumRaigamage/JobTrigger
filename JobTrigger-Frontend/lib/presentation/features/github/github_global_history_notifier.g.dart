// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_global_history_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs across the most recently updated repos, newest first
/// (`US-GH-HIST-02`). Requests run together; one repo failing (Actions
/// disabled, no access) does not hide the others. Only when every request
/// fails is the whole feed an error.

@ProviderFor(GitHubGlobalHistoryNotifier)
final gitHubGlobalHistoryNotifierProvider =
    GitHubGlobalHistoryNotifierProvider._();

/// Runs across the most recently updated repos, newest first
/// (`US-GH-HIST-02`). Requests run together; one repo failing (Actions
/// disabled, no access) does not hide the others. Only when every request
/// fails is the whole feed an error.
final class GitHubGlobalHistoryNotifierProvider
    extends $AsyncNotifierProvider<GitHubGlobalHistoryNotifier, GlobalRunFeed> {
  /// Runs across the most recently updated repos, newest first
  /// (`US-GH-HIST-02`). Requests run together; one repo failing (Actions
  /// disabled, no access) does not hide the others. Only when every request
  /// fails is the whole feed an error.
  GitHubGlobalHistoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitHubGlobalHistoryNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitHubGlobalHistoryNotifierHash();

  @$internal
  @override
  GitHubGlobalHistoryNotifier create() => GitHubGlobalHistoryNotifier();
}

String _$gitHubGlobalHistoryNotifierHash() =>
    r'a5f032a276f70bd81f171c26b4e9f78e73160ce1';

/// Runs across the most recently updated repos, newest first
/// (`US-GH-HIST-02`). Requests run together; one repo failing (Actions
/// disabled, no access) does not hide the others. Only when every request
/// fails is the whole feed an error.

abstract class _$GitHubGlobalHistoryNotifier
    extends $AsyncNotifier<GlobalRunFeed> {
  FutureOr<GlobalRunFeed> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GlobalRunFeed>, GlobalRunFeed>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GlobalRunFeed>, GlobalRunFeed>,
              AsyncValue<GlobalRunFeed>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
