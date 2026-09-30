// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact_download_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-PIPE-07. State is null when idle, [ArtifactProgress] while
/// downloading, and loading while the size is checked.
///
/// Deliberately not a bare external-browser link (see
/// `JenkinsRepository.downloadArtifact`): the file streams through the
/// authenticated Jenkins client into a temp file (never into memory,
/// AUD-21), goes to the OS share sheet, and is deleted. The app keeps no
/// copy.

@ProviderFor(ArtifactDownloadNotifier)
final artifactDownloadNotifierProvider = ArtifactDownloadNotifierFamily._();

/// US-PIPE-07. State is null when idle, [ArtifactProgress] while
/// downloading, and loading while the size is checked.
///
/// Deliberately not a bare external-browser link (see
/// `JenkinsRepository.downloadArtifact`): the file streams through the
/// authenticated Jenkins client into a temp file (never into memory,
/// AUD-21), goes to the OS share sheet, and is deleted. The app keeps no
/// copy.
final class ArtifactDownloadNotifierProvider
    extends
        $AsyncNotifierProvider<ArtifactDownloadNotifier, ArtifactProgress?> {
  /// US-PIPE-07. State is null when idle, [ArtifactProgress] while
  /// downloading, and loading while the size is checked.
  ///
  /// Deliberately not a bare external-browser link (see
  /// `JenkinsRepository.downloadArtifact`): the file streams through the
  /// authenticated Jenkins client into a temp file (never into memory,
  /// AUD-21), goes to the OS share sheet, and is deleted. The app keeps no
  /// copy.
  ArtifactDownloadNotifierProvider._({
    required ArtifactDownloadNotifierFamily super.from,
    required (String, String) super.argument,
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
        '$argument';
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
    r'f0caacfaad944e468991f152cea50c2d218df79a';

/// US-PIPE-07. State is null when idle, [ArtifactProgress] while
/// downloading, and loading while the size is checked.
///
/// Deliberately not a bare external-browser link (see
/// `JenkinsRepository.downloadArtifact`): the file streams through the
/// authenticated Jenkins client into a temp file (never into memory,
/// AUD-21), goes to the OS share sheet, and is deleted. The app keeps no
/// copy.

final class ArtifactDownloadNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ArtifactDownloadNotifier,
          AsyncValue<ArtifactProgress?>,
          ArtifactProgress?,
          FutureOr<ArtifactProgress?>,
          (String, String)
        > {
  ArtifactDownloadNotifierFamily._()
    : super(
        retry: null,
        name: r'artifactDownloadNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-PIPE-07. State is null when idle, [ArtifactProgress] while
  /// downloading, and loading while the size is checked.
  ///
  /// Deliberately not a bare external-browser link (see
  /// `JenkinsRepository.downloadArtifact`): the file streams through the
  /// authenticated Jenkins client into a temp file (never into memory,
  /// AUD-21), goes to the OS share sheet, and is deleted. The app keeps no
  /// copy.

  ArtifactDownloadNotifierProvider call(String buildUrl, String relativePath) =>
      ArtifactDownloadNotifierProvider._(
        argument: (buildUrl, relativePath),
        from: this,
      );

  @override
  String toString() => r'artifactDownloadNotifierProvider';
}

/// US-PIPE-07. State is null when idle, [ArtifactProgress] while
/// downloading, and loading while the size is checked.
///
/// Deliberately not a bare external-browser link (see
/// `JenkinsRepository.downloadArtifact`): the file streams through the
/// authenticated Jenkins client into a temp file (never into memory,
/// AUD-21), goes to the OS share sheet, and is deleted. The app keeps no
/// copy.

abstract class _$ArtifactDownloadNotifier
    extends $AsyncNotifier<ArtifactProgress?> {
  late final _$args = ref.$arg as (String, String);
  String get buildUrl => _$args.$1;
  String get relativePath => _$args.$2;

  FutureOr<ArtifactProgress?> build(String buildUrl, String relativePath);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ArtifactProgress?>, ArtifactProgress?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ArtifactProgress?>, ArtifactProgress?>,
              AsyncValue<ArtifactProgress?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
