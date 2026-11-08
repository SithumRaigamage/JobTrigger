import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'folder_breadcrumb_notifier.dart';
import 'folder_contents_notifier.dart';
import 'job_search_notifier.dart';
import 'views_notifier.dart';

part 'reachability_watcher.g.dart';

/// How often Home re-checks that the server is still there while open.
const reachabilityInterval = Duration(seconds: 30);

/// US-JX-20: notices a Jenkins outage (or its return) while Home is already
/// on screen — on a timer, and when the app comes back to the foreground.
/// Watched by `HomeScreen`, so it runs only while Home is mounted.
///
/// Search is skipped: its recursive crawl is too heavy to repeat just to
/// probe the server.
@riverpod
void reachabilityWatcher(Ref ref) {
  void check() {
    if (!ref.mounted || ref.read(jobSearchNotifierProvider).isNotEmpty) return;
    final breadcrumb = ref.read(folderBreadcrumbNotifierProvider);
    final root = ref.read(selectedViewNotifierProvider) ?? rootFolderKey;
    final folderKey = breadcrumb.isEmpty ? root : breadcrumb.last.url;
    unawaited(
      ref.read(folderContentsNotifierProvider(folderKey).notifier).recheck(),
    );
  }

  final timer = Timer.periodic(reachabilityInterval, (_) => check());
  final observer = _ResumeObserver(check);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    timer.cancel();
    WidgetsBinding.instance.removeObserver(observer);
  });
}

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this.onResume);

  final void Function() onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
