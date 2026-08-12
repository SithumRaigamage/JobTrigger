// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_tree_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches the full job tree from the active server — standard shape from
/// `docs/architecture.md §4`. `refresh()` backs pull-to-refresh on
/// `HomeScreen`.

@ProviderFor(JobTreeNotifier)
final jobTreeNotifierProvider = JobTreeNotifierProvider._();

/// Fetches the full job tree from the active server — standard shape from
/// `docs/architecture.md §4`. `refresh()` backs pull-to-refresh on
/// `HomeScreen`.
final class JobTreeNotifierProvider
    extends $AsyncNotifierProvider<JobTreeNotifier, List<JenkinsJob>> {
  /// Fetches the full job tree from the active server — standard shape from
  /// `docs/architecture.md §4`. `refresh()` backs pull-to-refresh on
  /// `HomeScreen`.
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

/// Fetches the full job tree from the active server — standard shape from
/// `docs/architecture.md §4`. `refresh()` backs pull-to-refresh on
/// `HomeScreen`.

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
