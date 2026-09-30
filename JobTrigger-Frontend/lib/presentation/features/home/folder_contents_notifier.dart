import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/cache/job_tree_cache.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../settings/active_server_notifier.dart';

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
///
/// US-JX-20: every successful listing is saved to [JobTreeCache]; on a
/// `NetworkFailure` the last saved listing is served instead, and
/// [OfflineSnapshotNotifier] records how old it is for Home's banner.
@riverpod
class FolderContentsNotifier extends _$FolderContentsNotifier {
  @override
  Future<List<JenkinsJob>> build(String folderUrl) async {
    final serverId =
        ref.watch(
          activeServerNotifierProvider.select((server) => server?.id),
        ) ??
        'none';
    final cache = ref.read(jobTreeCacheProvider);
    final result = await ref
        .watch(jenkinsRepositoryProvider)
        .fetchFolder(folderUrl == rootFolderKey ? null : folderUrl);

    switch (result) {
      case Ok(:final value):
        _markOnline();
        // Saved in the background: the listing is already in hand.
        unawaited(_bestEffort(() => cache.write(serverId, folderUrl, value)));
        return value;
      case Err(:final error) when error is NetworkFailure:
        final cached = await _bestEffort(() => cache.read(serverId, folderUrl));
        if (cached == null) throw error;
        if (ref.mounted) {
          ref
              .read(offlineSnapshotNotifierProvider.notifier)
              .markOffline(cached.savedAt);
        }
        return cached.jobs;
      case Err(:final error):
        throw error;
    }
  }

  void _markOnline() {
    if (ref.mounted) {
      ref.read(offlineSnapshotNotifierProvider.notifier).markOnline();
    }
  }

  /// The cache is a convenience: a filesystem problem must never break
  /// browsing, so it just behaves like an empty cache.
  static Future<T?> _bestEffort<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object {
      return null;
    }
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

/// US-JX-20: when Home is showing cached data, the time it was saved;
/// null when live.
@Riverpod(keepAlive: true)
class OfflineSnapshotNotifier extends _$OfflineSnapshotNotifier {
  @override
  DateTime? build() => null;

  void markOffline(DateTime savedAt) => state = savedAt;

  void markOnline() {
    if (state != null) state = null;
  }
}
