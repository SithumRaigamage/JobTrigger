// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visible_jobs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The jobs `HomeScreen` shows (replaces `filteredJobsProvider`, P11-05).
///
/// - **No search:** the current breadcrumb folder's children, fetched
///   lazily by `FolderContentsNotifier`.
/// - **Search:** the recursive crawl (`JobTreeNotifier`, fetched only once
///   someone searches) flattened and filtered by label or name across
///   every folder, as `HomeViewModel.displayedJobs` (Swift) did.
///
/// An `AsyncValue` because both sources load on demand; `HomeScreen`
/// renders its loading and error states.

@ProviderFor(visibleJobs)
final visibleJobsProvider = VisibleJobsProvider._();

/// The jobs `HomeScreen` shows (replaces `filteredJobsProvider`, P11-05).
///
/// - **No search:** the current breadcrumb folder's children, fetched
///   lazily by `FolderContentsNotifier`.
/// - **Search:** the recursive crawl (`JobTreeNotifier`, fetched only once
///   someone searches) flattened and filtered by label or name across
///   every folder, as `HomeViewModel.displayedJobs` (Swift) did.
///
/// An `AsyncValue` because both sources load on demand; `HomeScreen`
/// renders its loading and error states.

final class VisibleJobsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<JenkinsJob>>,
          AsyncValue<List<JenkinsJob>>,
          AsyncValue<List<JenkinsJob>>
        >
    with $Provider<AsyncValue<List<JenkinsJob>>> {
  /// The jobs `HomeScreen` shows (replaces `filteredJobsProvider`, P11-05).
  ///
  /// - **No search:** the current breadcrumb folder's children, fetched
  ///   lazily by `FolderContentsNotifier`.
  /// - **Search:** the recursive crawl (`JobTreeNotifier`, fetched only once
  ///   someone searches) flattened and filtered by label or name across
  ///   every folder, as `HomeViewModel.displayedJobs` (Swift) did.
  ///
  /// An `AsyncValue` because both sources load on demand; `HomeScreen`
  /// renders its loading and error states.
  VisibleJobsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleJobsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleJobsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<JenkinsJob>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<JenkinsJob>> create(Ref ref) {
    return visibleJobs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<JenkinsJob>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<JenkinsJob>>>(value),
    );
  }
}

String _$visibleJobsHash() => r'61b6dddc2414c0e5336a8d50156fc1ad3f773dca';
