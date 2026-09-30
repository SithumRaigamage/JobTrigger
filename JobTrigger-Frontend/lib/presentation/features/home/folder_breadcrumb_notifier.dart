import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/jenkins/jenkins_job.dart';
import '../settings/active_server_notifier.dart';

part 'folder_breadcrumb_notifier.g.dart';

/// One level of the folder breadcrumb: where it is and what to call it.
/// Deliberately **not** a `JenkinsJob` snapshot — the old breadcrumb kept
/// the folder object it was entered through and showed *its* children, so
/// pull-to-refresh inside a folder showed stale contents (AUD-10). The
/// children now always come from `FolderContentsNotifier` for [url].
class FolderRef {
  const FolderRef({required this.url, required this.label});

  factory FolderRef.of(JenkinsJob folder) =>
      FolderRef(url: folder.url, label: folder.label);

  final String url;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is FolderRef && other.url == url && other.label == label;

  @override
  int get hashCode => Object.hash(url, label);
}

/// Navigation stack for folder drill-down — pure local UI state, no
/// repository calls (`docs/state-management.md`). `navigateInto`/
/// `navigateBack` port `HomeViewModel.navigateInto`/`navigateBack` (Swift).
///
/// Watches the active server, so switching servers rebuilds this back to
/// the root — previously the breadcrumb (and the folder contents it held)
/// survived a switch, showing server A's folder under server B (AUD-10).
@riverpod
class FolderBreadcrumbNotifier extends _$FolderBreadcrumbNotifier {
  @override
  List<FolderRef> build() {
    ref.watch(activeServerNotifierProvider.select((server) => server?.id));
    return const [];
  }

  void navigateInto(JenkinsJob folder) {
    if (!folder.isFolder) return;
    state = [...state, FolderRef.of(folder)];
  }

  void navigateBack() {
    if (state.isEmpty) return;
    state = state.sublist(0, state.length - 1);
  }

  void reset() => state = const [];
}
