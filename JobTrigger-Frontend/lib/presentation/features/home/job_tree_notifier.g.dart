// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_tree_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The recursive crawl of the active server (6 folder levels) — standard
/// shape from `docs/architecture.md §4`. Since P11-05 it backs only
/// cross-folder search and the global history timeline; Home browses
/// lazily with `FolderContentsNotifier`. So it's first fetched when someone
/// searches or opens global history, not on every Home load (AUD-20).

@ProviderFor(JobTreeNotifier)
final jobTreeNotifierProvider = JobTreeNotifierProvider._();

/// The recursive crawl of the active server (6 folder levels) — standard
/// shape from `docs/architecture.md §4`. Since P11-05 it backs only
/// cross-folder search and the global history timeline; Home browses
/// lazily with `FolderContentsNotifier`. So it's first fetched when someone
/// searches or opens global history, not on every Home load (AUD-20).
final class JobTreeNotifierProvider
    extends $AsyncNotifierProvider<JobTreeNotifier, List<JenkinsJob>> {
  /// The recursive crawl of the active server (6 folder levels) — standard
  /// shape from `docs/architecture.md §4`. Since P11-05 it backs only
  /// cross-folder search and the global history timeline; Home browses
  /// lazily with `FolderContentsNotifier`. So it's first fetched when someone
  /// searches or opens global history, not on every Home load (AUD-20).
  JobTreeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobTreeNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobTreeNotifierHash();

  @$internal
  @override
  JobTreeNotifier create() => JobTreeNotifier();
}

String _$jobTreeNotifierHash() => r'd366ad898da3471d24a16e9e4fabfc546a6cfe77';

/// The recursive crawl of the active server (6 folder levels) — standard
/// shape from `docs/architecture.md §4`. Since P11-05 it backs only
/// cross-folder search and the global history timeline; Home browses
/// lazily with `FolderContentsNotifier`. So it's first fetched when someone
/// searches or opens global history, not on every Home load (AUD-20).

abstract class _$JobTreeNotifier extends $AsyncNotifier<List<JenkinsJob>> {
  FutureOr<List<JenkinsJob>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<JenkinsJob>>, List<JenkinsJob>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<JenkinsJob>>, List<JenkinsJob>>,
              AsyncValue<List<JenkinsJob>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
