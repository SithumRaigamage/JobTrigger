// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact_download_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-PIPE-07. Family-keyed by the artifact's `relativePath` (unique
/// within one build) so each artifact row has its own independent
/// loading/error state.
///
/// Deliberately not a bare external-browser link (see `JenkinsRepository
/// .fetchArtifactBytes`'s doc comment): fetches the bytes through the
/// already-authenticated Jenkins client, writes them to a temp file, then
/// hands off via the OS share sheet — same pattern as `BuildLogScreen`'s
/// existing "Share log" action, just with bytes instead of text.

@ProviderFor(ArtifactDownloadNotifier)
final artifactDownloadNotifierProvider = ArtifactDownloadNotifierFamily._();

/// US-PIPE-07. Family-keyed by the artifact's `relativePath` (unique
/// within one build) so each artifact row has its own independent
/// loading/error state.
///
/// Deliberately not a bare external-browser link (see `JenkinsRepository
/// .fetchArtifactBytes`'s doc comment): fetches the bytes through the
/// already-authenticated Jenkins client, writes them to a temp file, then
/// hands off via the OS share sheet — same pattern as `BuildLogScreen`'s
/// existing "Share log" action, just with bytes instead of text.
final class ArtifactDownloadNotifierProvider
    extends $AsyncNotifierProvider<ArtifactDownloadNotifier, void> {
  /// US-PIPE-07. Family-keyed by the artifact's `relativePath` (unique
  /// within one build) so each artifact row has its own independent
  /// loading/error state.
  ///
  /// Deliberately not a bare external-browser link (see `JenkinsRepository
  /// .fetchArtifactBytes`'s doc comment): fetches the bytes through the
  /// already-authenticated Jenkins client, writes them to a temp file, then
  /// hands off via the OS share sheet — same pattern as `BuildLogScreen`'s
  /// existing "Share log" action, just with bytes instead of text.
  ArtifactDownloadNotifierProvider._({
    required ArtifactDownloadNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'artifactDownloadNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$artifactDownloadNotifierHash();

  @override
  String toString() {
    return r'artifactDownloadNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ArtifactDownloadNotifier create() => ArtifactDownloadNotifier();

  @override
  bool operator ==(Object other) {
    return other is ArtifactDownloadNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$artifactDownloadNotifierHash() =>
    r'0ae2cc1503c2849eff439603113888ef31e2f195';

/// US-PIPE-07. Family-keyed by the artifact's `relativePath` (unique
/// within one build) so each artifact row has its own independent
/// loading/error state.
///
/// Deliberately not a bare external-browser link (see `JenkinsRepository
/// .fetchArtifactBytes`'s doc comment): fetches the bytes through the
/// already-authenticated Jenkins client, writes them to a temp file, then
/// hands off via the OS share sheet — same pattern as `BuildLogScreen`'s
/// existing "Share log" action, just with bytes instead of text.

final class ArtifactDownloadNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ArtifactDownloadNotifier,
          AsyncValue<void>,
          void,
          FutureOr<void>,
          String
        > {
  ArtifactDownloadNotifierFamily._()
    : super(
        retry: null,
        name: r'artifactDownloadNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-PIPE-07. Family-keyed by the artifact's `relativePath` (unique
  /// within one build) so each artifact row has its own independent
  /// loading/error state.
  ///
  /// Deliberately not a bare external-browser link (see `JenkinsRepository
  /// .fetchArtifactBytes`'s doc comment): fetches the bytes through the
  /// already-authenticated Jenkins client, writes them to a temp file, then
  /// hands off via the OS share sheet — same pattern as `BuildLogScreen`'s
  /// existing "Share log" action, just with bytes instead of text.

  ArtifactDownloadNotifierProvider call(String relativePath) =>
      ArtifactDownloadNotifierProvider._(argument: relativePath, from: this);

  @override
  String toString() => r'artifactDownloadNotifierProvider';
}

/// US-PIPE-07. Family-keyed by the artifact's `relativePath` (unique
/// within one build) so each artifact row has its own independent
/// loading/error state.
///
/// Deliberately not a bare external-browser link (see `JenkinsRepository
/// .fetchArtifactBytes`'s doc comment): fetches the bytes through the
/// already-authenticated Jenkins client, writes them to a temp file, then
/// hands off via the OS share sheet — same pattern as `BuildLogScreen`'s
/// existing "Share log" action, just with bytes instead of text.

abstract class _$ArtifactDownloadNotifier extends $AsyncNotifier<void> {
  late final _$args = ref.$arg as String;
  String get relativePath => _$args;

  FutureOr<void> build(String relativePath);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
