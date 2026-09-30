import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/platform/temp_files.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/build_artifact.dart';
import '../../common_widgets/toast_controller.dart';

part 'artifact_download_notifier.g.dart';

/// Bytes received so far, and the total when the server said.
class ArtifactProgress {
  const ArtifactProgress(this.received, this.total);

  final int received;
  final int? total;

  /// 0–1, or null when the total is unknown.
  double? get fraction {
    final total = this.total;
    return total == null || total <= 0 ? null : received / total;
  }
}

/// US-PIPE-07. State is null when idle, [ArtifactProgress] while
/// downloading, and loading while the size is checked.
///
/// Deliberately not a bare external-browser link (see
/// `JenkinsRepository.downloadArtifact`): the file streams through the
/// authenticated Jenkins client into a temp file (never into memory,
/// AUD-21), goes to the OS share sheet, and is deleted. The app keeps no
/// copy.
@riverpod
class ArtifactDownloadNotifier extends _$ArtifactDownloadNotifier {
  /// Above this, the user confirms first (AUD-21).
  static const largeBytes = 100 * 1024 * 1024;

  @override
  // Keyed by build *and* path: the same relative path in two builds (or
  // jobs) is a different file with its own download state (AUD-29).
  FutureOr<ArtifactProgress?> build(String buildUrl, String relativePath) =>
      null;

  /// Downloads [artifact] and shares it. If it's over [largeBytes] and
  /// [allowLarge] is false, nothing is downloaded and its size is
  /// returned, so the caller can confirm and call again with
  /// `allowLarge: true`. Otherwise returns null.
  Future<int?> download(
    BuildArtifact artifact, {
    bool allowLarge = false,
  }) async {
    if (state.isLoading || state.value != null) return null; // Running.
    final repository = ref.read(jenkinsRepositoryProvider);

    if (!allowLarge) {
      state = const AsyncLoading();
      final size = await repository.fetchArtifactSize(buildUrl, relativePath);
      if (!ref.mounted) return null;
      // An unknown size (no Content-Length, or a failed HEAD) doesn't
      // block the download; the GET reports any real error.
      if (size case Ok(value: final bytes?) when bytes > largeBytes) {
        state = const AsyncData(null);
        return bytes;
      }
    }

    state = const AsyncData(ArtifactProgress(0, null));
    final directory = await ref.read(tempDirectoryProvider.future);
    // Its own folder, so two artifacts with the same file name can't
    // collide.
    final folder = await directory.createTemp('artifact_');
    final path = '${folder.path}/${artifact.fileName}';
    try {
      final result = await repository.downloadArtifact(
        buildUrl,
        relativePath,
        path,
        onProgress: (received, total) {
          if (ref.mounted) state = AsyncData(ArtifactProgress(received, total));
        },
      );
      if (!ref.mounted) return null;
      switch (result) {
        case Ok():
          await ref.read(fileSharerProvider)(path, artifact.fileName);
          if (ref.mounted) state = const AsyncData(null);
        case Err(:final error):
          _fail(error);
      }
    } finally {
      if (folder.existsSync()) folder.deleteSync(recursive: true);
    }
    return null;
  }

  void _fail(AppFailure error) {
    state = AsyncError(error, StackTrace.current);
    ref
        .read(toastControllerProvider)
        .show(
          type: ToastType.error,
          title: 'Download Failed',
          message: error.message,
        );
  }
}
