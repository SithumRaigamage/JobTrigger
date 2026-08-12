import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/jenkins/jenkins_job.dart';

part 'folder_breadcrumb_notifier.g.dart';

/// Navigation stack for folder drill-down — pure local UI state, no
/// repository calls (`docs/state-management.md`). `navigateInto`/
/// `navigateBack` port `HomeViewModel.navigateInto`/`navigateBack` (Swift).
@riverpod
class FolderBreadcrumbNotifier extends _$FolderBreadcrumbNotifier {
  @override
  List<JenkinsJob> build() => const [];

  void navigateInto(JenkinsJob folder) {
    if (!folder.isFolder) return;
    state = [...state, folder];
  }

  void navigateBack() {
    if (state.isEmpty) return;
    state = state.sublist(0, state.length - 1);
  }

  void reset() => state = const [];
}
