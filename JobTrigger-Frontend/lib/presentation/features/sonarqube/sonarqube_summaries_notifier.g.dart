// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_summaries_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches summaries for whatever projects are on screen, once each, in
/// batches. A failure leaves the projects as they were and can be retried.
/// Rebuilds, and so forgets everything, when the credential changes.

@ProviderFor(SonarQubeSummariesNotifier)
final sonarQubeSummariesNotifierProvider =
    SonarQubeSummariesNotifierProvider._();

/// Fetches summaries for whatever projects are on screen, once each, in
/// batches. A failure leaves the projects as they were and can be retried.
/// Rebuilds, and so forgets everything, when the credential changes.
final class SonarQubeSummariesNotifierProvider
    extends $NotifierProvider<SonarQubeSummariesNotifier, SonarQubeSummaries> {
  /// Fetches summaries for whatever projects are on screen, once each, in
  /// batches. A failure leaves the projects as they were and can be retried.
  /// Rebuilds, and so forgets everything, when the credential changes.
  SonarQubeSummariesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeSummariesNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeSummariesNotifierHash();

  @$internal
  @override
  SonarQubeSummariesNotifier create() => SonarQubeSummariesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SonarQubeSummaries value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SonarQubeSummaries>(value),
    );
  }
}

String _$sonarQubeSummariesNotifierHash() =>
    r'd2e96a48049ed5700d033c52ab17520b53662b22';

/// Fetches summaries for whatever projects are on screen, once each, in
/// batches. A failure leaves the projects as they were and can be retried.
/// Rebuilds, and so forgets everything, when the credential changes.

abstract class _$SonarQubeSummariesNotifier
    extends $Notifier<SonarQubeSummaries> {
  SonarQubeSummaries build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SonarQubeSummaries, SonarQubeSummaries>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SonarQubeSummaries, SonarQubeSummaries>,
              SonarQubeSummaries,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
