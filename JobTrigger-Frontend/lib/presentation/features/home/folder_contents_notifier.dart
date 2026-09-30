import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/jenkins_job.dart';

part 'folder_contents_notifier.g.dart';

/// Family key for the server root in [FolderContentsNotifier].
const rootFolderKey = '';

/// One folder's direct children, fetched on demand (P11-05) — [folderUrl]
/// is [rootFolderKey] for the server root. Home browses with this instead
/// of downloading the whole recursive tree up front (AUD-20), and a folder
/// is fetchable at any depth (AUD-19).
///
/// Cached for as long as it's on the current breadcrumb path —
/// `visibleJobsProvider` watches every ancestor — so walking back up
/// doesn't flash a spinner, and nothing lingers once Home is left.
/// Pull-to-refresh calls [refresh] for an immediate re-fetch. Rebuilt
/// automatically when the active server changes, via
/// `jenkinsRepositoryProvider`.
@riverpod
class FolderContentsNotifier extends _$FolderContentsNotifier {
  @override
  Future<List<JenkinsJob>> build(String folderUrl) async {
    final result = await ref
        .watch(jenkinsRepositoryProvider)
        .fetchFolder(folderUrl == rootFolderKey ? null : folderUrl);
    return result.fold((jobs) => jobs, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
