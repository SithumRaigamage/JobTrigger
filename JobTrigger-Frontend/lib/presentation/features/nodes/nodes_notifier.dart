import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/jenkins_node.dart';
import '../../common_widgets/toast_controller.dart';
import '../app_lock/app_lock_notifier.dart';

part 'nodes_notifier.g.dart';

/// What the nodes screen shows (US-JX-12).
class NodesState {
  const NodesState({required this.nodes, this.canToggle = true});

  final List<JenkinsNode> nodes;

  /// False once the server refused a toggle (403): the switch is hidden
  /// for the rest of the session instead of failing on every tap.
  final bool canToggle;
}

/// US-JX-12: nodes and their executors, refreshed every [_refreshEvery]
/// while the screen is open. The timer is cancelled on dispose.
@riverpod
class NodesNotifier extends _$NodesNotifier {
  static const _refreshEvery = Duration(seconds: 10);
  bool _canToggle = true;

  @override
  Future<NodesState> build() async {
    final timer = Timer(_refreshEvery, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
    final result = await ref.watch(jenkinsRepositoryProvider).fetchNodes();
    final nodes = result.fold((nodes) => nodes, (failure) => throw failure);
    return NodesState(nodes: nodes, canToggle: _canToggle);
  }

  /// Takes [node] temporarily offline (with [reason]) or brings it back.
  Future<void> toggleOffline(JenkinsNode node, {String reason = ''}) async {
    // US-JX-21: re-prompt when the user asked for it.
    final allowed = await ref
        .read(appLockNotifierProvider.notifier)
        .confirmSensitive('Confirm to change ${node.displayName}');
    if (!allowed || !ref.mounted) return;
    final result = await ref
        .read(jenkinsRepositoryProvider)
        .toggleNodeOffline(node, message: reason);
    if (!ref.mounted) return;
    final toast = ref.read(toastControllerProvider);
    switch (result) {
      case Ok():
        ref.invalidateSelf();
        toast.show(
          type: ToastType.success,
          title: node.temporarilyOffline ? 'Node back online' : 'Node offline',
          message: node.temporarilyOffline
              ? '${node.displayName} will accept builds again.'
              : '${node.displayName} will take no new builds.',
        );
      case Err(:final error):
        if (error is PermissionFailure) {
          _canToggle = false;
          final current = state.value;
          if (current != null) {
            state = AsyncData(
              NodesState(nodes: current.nodes, canToggle: false),
            );
          }
        }
        toast.show(
          type: ToastType.error,
          title: "Couldn't change ${node.displayName}",
          message: error.message,
        );
    }
  }
}
