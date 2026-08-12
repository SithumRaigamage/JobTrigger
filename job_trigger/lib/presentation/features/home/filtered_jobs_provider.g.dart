// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filtered_jobs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The jobs `HomeScreen` should actually display — ported from
/// `HomeViewModel.displayedJobs` (Swift): empty search shows the current
/// breadcrumb folder's contents; a non-empty search flattens and filters
/// the *entire* tree by name, regardless of which folder is open.

@ProviderFor(filteredJobs)
final filteredJobsProvider = FilteredJobsProvider._();

/// The jobs `HomeScreen` should actually display — ported from
/// `HomeViewModel.displayedJobs` (Swift): empty search shows the current
/// breadcrumb folder's contents; a non-empty search flattens and filters
/// the *entire* tree by name, regardless of which folder is open.

final class FilteredJobsProvider
    extends
        $FunctionalProvider<
          List<JenkinsJob>,
          List<JenkinsJob>,
          List<JenkinsJob>
        >
    with $Provider<List<JenkinsJob>> {
  /// The jobs `HomeScreen` should actually display — ported from
  /// `HomeViewModel.displayedJobs` (Swift): empty search shows the current
  /// breadcrumb folder's contents; a non-empty search flattens and filters
  /// the *entire* tree by name, regardless of which folder is open.
  FilteredJobsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredJobsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredJobsHash();

  @$internal
  @override
  $ProviderElement<List<JenkinsJob>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<JenkinsJob> create(Ref ref) {
    return filteredJobs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<JenkinsJob> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<JenkinsJob>>(value),
    );
  }
}

String _$filteredJobsHash() => r'ae87005b05474faa051bc88d90d0b2ed8e4677ec';
