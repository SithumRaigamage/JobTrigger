import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/branch_kind.dart';
import '../../common_widgets/toast_controller.dart';
import 'folder_contents_notifier.dart';

part 'multibranch_notifiers.g.dart';

/// US-JX-03: branch / pull request / tag classification for the jobs of
/// the multibranch project at [projectUrl], keyed by job `name`. Only
/// fetched while Home is showing that project.
@riverpod
Future<Map<String, BranchKind>> branchKinds(Ref ref, String projectUrl) async {
  final result = await ref
      .watch(jenkinsRepositoryProvider)
      .fetchBranchKinds(projectUrl);
  return result.fold((kinds) => kinds, (failure) => throw failure);
}

/// US-JX-03 "Scan now" for a multibranch project or organization folder.
/// State is `true` while a scan is being requested or running.
///
/// After the POST, polls the indexing log (`{projectUrl}indexing/`,
/// Jenkins' progressive-text contract, where `X-More-Data` means still
/// running) every [_pollEvery], then refreshes the project's contents and
/// branch groups. The timer is cancelled on dispose, the same leak
/// discipline as `BuildStatusPollingNotifier`.
@riverpod
class MultibranchScanNotifier extends _$MultibranchScanNotifier {
  static const _pollEvery = Duration(seconds: 2);
  static const _maxPolls = 150; // 5 minutes: a scan can't hold the UI forever.

  Timer? _timer;
  int _polls = 0;

  @override
  bool build(String projectUrl) {
    ref.onDispose(() => _timer?.cancel());
    return false;
  }

  String get _indexingUrl =>
      '${projectUrl.endsWith('/') ? projectUrl : '$projectUrl/'}indexing/';

  Future<void> scan() async {
    if (state) return;
    state = true;
    final result = await ref
        .read(jenkinsRepositoryProvider)
        .scanMultibranch(projectUrl);
    if (!ref.mounted) return;
    final toast = ref.read(toastControllerProvider);
    switch (result) {
      case Ok():
        toast.show(
          type: ToastType.success,
          title: 'Scan started',
          message: 'Looking for new branches…',
        );
        _polls = 0;
        _schedulePoll();
      case Err(:final error):
        state = false;
        toast.show(
          type: ToastType.error,
          title: 'Scan failed',
          message: error.message,
        );
    }
  }

  void _schedulePoll() {
    _timer?.cancel();
    _timer = Timer(_pollEvery, () async {
      final result = await ref
          .read(jenkinsRepositoryProvider)
          .streamBuildLog(_indexingUrl);
      if (!ref.mounted) return;
      final running = switch (result) {
        Ok(:final value) => value.hasMoreData,
        Err() => false,
      };
      if (running && ++_polls < _maxPolls) {
        _schedulePoll();
        return;
      }
      state = false;
      ref
        ..invalidate(folderContentsNotifierProvider(projectUrl))
        ..invalidate(branchKindsProvider(projectUrl));
      ref
          .read(toastControllerProvider)
          .show(
            type: ToastType.info,
            title: 'Scan finished',
            message: 'Branches are up to date.',
          );
    });
  }
}
