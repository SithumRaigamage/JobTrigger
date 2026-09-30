import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_node.dart';
import '../../../domain/jenkins/parameter_file.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import 'nodes_notifier.dart';

/// US-JX-12: which agents are online and busy, what they're running, and
/// a way to take one temporarily offline (with a reason) or back online.
class NodesScreen extends ConsumerWidget {
  const NodesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(nodesNotifierProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Nodes')),
      body: ResponsiveCenter(
        child: nodes.when(
          skipLoadingOnRefresh: true,
          data: (state) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(nodesNotifierProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
                16,
                16,
              ),
              children: [
                for (final node in state.nodes) ...[
                  _NodeCard(node: node, canToggle: state.canToggle),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: ConnectionErrorView(
              message: describeError(error),
              onRetry: () => ref.invalidate(nodesNotifierProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeCard extends ConsumerWidget {
  const _NodeCard({required this.node, required this.canToggle});

  final JenkinsNode node;
  final bool canToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final online = !node.offline;
    final status = node.temporarilyOffline
        ? 'Marked offline'
        : online
        ? 'Online'
        : 'Offline';
    return GlassSurface.card(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        shape: const Border(),
        leading: Icon(
          online ? Icons.dns : Icons.cloud_off,
          color: online ? AppColors.buildSuccess : AppColors.buildAborted,
          semanticLabel: status,
        ),
        title: Text(node.displayName, style: textTheme.bodyLarge),
        subtitle: Text(
          [
            status,
            if (node.offlineReason case final reason?) '"$reason"',
            '${node.busyExecutors}/${node.numExecutors} busy',
            if (node.lowDiskSpace)
              'Low disk: ${formatFileSize(node.diskFreeBytes!)} free',
          ].join(' · '),
          style: textTheme.bodySmall,
        ),
        trailing: canToggle
            ? Switch(
                value: !node.temporarilyOffline,
                onChanged: (_) => _confirmToggle(context, ref),
              )
            : null,
        children: [
          if (node.running.isEmpty)
            const ListTile(dense: true, title: Text('No builds running'))
          else
            for (final run in node.running)
              ListTile(
                dense: true,
                leading: const Icon(Icons.autorenew, size: 18),
                title: Text(run.name),
                subtitle: run.progress == null
                    ? null
                    : LinearProgressIndicator(value: run.progress! / 100),
                onTap: () => context.push(
                  AppRoutes.buildDetail,
                  extra: JenkinsBuild(
                    number: 0,
                    url: run.url,
                    timestamp: 0,
                    displayName: run.name,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _confirmToggle(BuildContext context, WidgetRef ref) async {
    final goingOffline = !node.temporarilyOffline;
    String reason = '';
    final confirmed = await showConfirmationDialog(
      context,
      title: goingOffline
          ? 'Take ${node.displayName} offline?'
          : 'Bring ${node.displayName} back online?',
      message: goingOffline
          ? 'It will take no new builds. Running builds carry on.'
          : 'It will accept builds again.',
      confirmLabel: goingOffline ? 'Take offline' : 'Bring online',
      destructive: goingOffline,
      details: goingOffline
          ? TextField(
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. disk cleanup',
              ),
              onChanged: (value) => reason = value.trim(),
            )
          : null,
    );
    if (!confirmed) return;
    await ref
        .read(nodesNotifierProvider.notifier)
        .toggleOffline(node, reason: reason);
  }
}
