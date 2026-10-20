// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_tree_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(jobTreeCache)
final jobTreeCacheProvider = JobTreeCacheProvider._();

final class JobTreeCacheProvider
    extends $FunctionalProvider<JobTreeCache, JobTreeCache, JobTreeCache>
    with $Provider<JobTreeCache> {
  JobTreeCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobTreeCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobTreeCacheHash();

  @$internal
  @override
  $ProviderElement<JobTreeCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  JobTreeCache create(Ref ref) {
    return jobTreeCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JobTreeCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JobTreeCache>(value),
    );
  }
}

String _$jobTreeCacheHash() => r'1a4d850ff8843cd695d695134ed839c52e1844bd';
