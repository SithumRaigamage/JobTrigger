import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/build_artifact.dart';
import '../../common_widgets/toast_controller.dart';

part 'artifact_download_notifier.g.dart';

/// US-PIPE-07. Family-keyed by the artifact's `relativePath` (unique
/// within one build) so each artifact row has its own independent
/// loading/error state.
///
/// Deliberately not a bare external-browser link (see `JenkinsRepository
/// .fetchArtifactBytes`'s doc comment): fetches the bytes through the
/// already-authenticated Jenkins client, writes them to a temp file, then
/// hands off via the OS share sheet — same pattern as `BuildLogScreen`'s
/// existing "Share log" action, just with bytes instead of text.
@riverpod
class ArtifactDownloadNotifier extends _$ArtifactDownloadNotifier {
  @override
  FutureOr<void> build(String relativePath) {}

  Future<void> download({
    required String buildUrl,
    required BuildArtifact artifact,
  }) async {
    state = const AsyncLoading();

    final result = await ref
        .read(jenkinsRepositoryProvider)
        .fetchArtifactBytes(buildUrl, artifact.relativePath);

    switch (result) {
      case Ok(:final value):
        final tempDir = await Directory.systemTemp.createTemp(
          'job_trigger_artifact_',
        );
        final file = File('${tempDir.path}/${artifact.fileName}');
        await file.writeAsBytes(value);
        state = const AsyncData(null);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      case Err(:final error):
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
}
