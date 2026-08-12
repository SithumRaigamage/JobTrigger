// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_search_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(JobSearchNotifier)
final jobSearchNotifierProvider = JobSearchNotifierProvider._();

final class JobSearchNotifierProvider
    extends $NotifierProvider<JobSearchNotifier, String> {
  JobSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jobSearchNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jobSearchNotifierHash();

  @$internal
  @override
  JobSearchNotifier create() => JobSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$jobSearchNotifierHash() => r'2f8450b2f4028988570615aa178ce58dc75d0a1f';

abstract class _$JobSearchNotifier extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
