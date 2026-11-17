import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_repository.dart';
import '../../common_widgets/toast_controller.dart';

part 'build_detail_notifier.g.dart';

/// US-JX-14: one build in full, plus its two edits. Each edit re-reads
/// the build instead of assuming the result: `toggleLogKeep` *toggles*,
/// so a local flip could drift from the server.
@riverpod
class BuildDetailNotifier extends _$BuildDetailNotifier {
  @override
  Future<JenkinsBuild> build(String buildUrl) async {
    final result = await ref
        .watch(jenkinsRepositoryProvider)
        .fetchBuildDetail(buildUrl);
    return result.fold((build) => build, (failure) => throw failure);
  }

  Future<void> toggleKeepForever() => _edit(
    (repository) => repository.toggleKeepLog(buildUrl),
    success: 'Keep forever updated',
  );

  Future<void> setDescription(String description) => _edit(
    (repository) => repository.setBuildDescription(buildUrl, description),
    success: description.isEmpty ? 'Description cleared' : 'Description saved',
  );

  Future<void> _edit(
    Future<Result<void, AppFailure>> Function(JenkinsRepository) action, {
    required String success,
  }) async {
    final result = await action(ref.read(jenkinsRepositoryProvider));
    if (!ref.mounted) return;
    final toast = ref.read(toastControllerProvider);
    switch (result) {
      case Ok():
        ref.invalidateSelf();
        toast.show(type: ToastType.success, title: success, message: '');
      case Err(:final error):
        toast.show(
          type: ToastType.error,
          title: "Couldn't save",
          message: error.message,
        );
    }
  }
}
