import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_node.dart';
import '../../../domain/jenkins/parameter_file.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import 'nodes_notifier.dart';

/// US-JX-12: which agents are online and busy, what they're running, and
/// a way to take one temporarily offline (with a reason) or back online.
/// Laid out to the P14 design (`UI-UX/screens/16-nodes`).
class NodesScreen extends ConsumerWidget {
  const NodesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(nodesNotifierProvider);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ResponsiveCenter(
                child: nodes.when(
                  skipLoadingOnRefresh: true,
                  data: (state) => RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(nodesNotifierProvider),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        Semantics(
                          header: true,
                          child: Text('Nodes', style: textTheme.headlineMedium),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _summary(state.nodes),
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppTokens.of(context).textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final node in state.nodes) ...[
                          _NodeCard(node: node, canToggle: state.canToggle),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref.invalidate(nodesNotifierProvider),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "3 online · 1 offline · 5 of 10 executors busy".
  static String _summary(List<JenkinsNode> nodes) {
    final online = nodes.where((node) => !node.offline).length;
    final busy = nodes.fold(0, (sum, node) => sum + node.busyExecutors);
    final total = nodes.fold(0, (sum, node) => sum + node.numExecutors);
    return [
      '$online online',
      if (nodes.length > online) '${nodes.length - online} offline',
      '$busy of $total executors busy',
    ].join(' · ');
  }
}

class _NodeCard extends ConsumerWidget {
  const _NodeCard({required this.node, required this.canToggle});

  final JenkinsNode node;
  final bool canToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final online = !node.offline;
    final status = node.temporarilyOffline
        ? 'Marked offline'
        : online
        ? 'Online'
        : 'Offline';
    final mono = AppTypography.mono(textTheme.bodySmall).copyWith(fontSize: 12);
    return GlassSurface.card(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  node.displayName,
                  style: AppTypography.mono(textTheme.titleSmall),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online ? t.success.dot : null,
                  border: online
                      ? null
                      : Border.all(color: t.neutral.dot, width: 2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: textTheme.labelSmall?.copyWith(
                  color: online ? t.success.foreground : t.textSecondary,
                ),
              ),
            ],
          ),
          if (node.offlineReason case final reason?) ...[
            const SizedBox(height: 6),
            Text('“$reason”', style: textTheme.bodySmall),
          ],
          if (node.numExecutors > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Executors', style: textTheme.bodySmall)),
                Text(
                  '${node.busyExecutors} / ${node.numExecutors} busy',
                  style: mono.copyWith(color: t.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < node.numExecutors; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: i < node.busyExecutors
                              ? t.running.dot
                              : t.raised,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (node.lowDiskSpace) ...[
            const SizedBox(height: 10),
            InlineAlert(
              tone: StatusTone.unstable,
              icon: Icons.storage_rounded,
              message: 'Low disk: ${formatFileSize(node.diskFreeBytes!)} free',
            ),
          ],
          for (final run in node.running) ...[
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.push(
                AppRoutes.buildDetail,
                extra: JenkinsBuild(
                  number: 0,
                  url: run.url,
                  timestamp: 0,
                  displayName: run.name,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.autorenew_rounded,
                      size: 16,
                      color: t.running.foreground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(run.name, style: textTheme.bodyMedium),
                          if (run.progress case final progress?) ...[
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: progress / 100,
                              semanticsLabel: 'Build progress',
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: t.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (canToggle) ...[
            const SizedBox(height: 4),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Accepting builds'),
              value: !node.temporarilyOffline,
              onChanged: (_) => _confirmToggle(context, ref),
            ),
          ],
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
