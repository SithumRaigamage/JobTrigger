import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/queue_entry.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import 'queue_notifier.dart';

/// US-JX-09: everything waiting for an executor, why it's waiting, and a
/// way to cancel an item. Refreshes every 5 s while open. Laid out to the
/// P14 design (`UI-UX/screens/17-queue`).
class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueNotifierProvider);
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
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
                child: queue.when(
                  skipLoadingOnRefresh: true,
                  data: (items) => RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(queueNotifierProvider),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Build queue',
                            style: textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            switch (items.length) {
                              0 => 'Nothing waiting',
                              1 => '1 build waiting',
                              final n => '$n builds waiting',
                            },
                            'refreshes every 5s',
                          ].join(' · '),
                          style: textTheme.bodyMedium?.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 40,
                                  color: t.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Nothing is waiting',
                                  style: textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        for (final (i, item) in items.indexed) ...[
                          _QueueTile(entry: item, position: i + 1),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref.invalidate(queueNotifierProvider),
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
}

class _QueueTile extends ConsumerWidget {
  const _QueueTile({required this.entry, required this.position});

  final QueueEntry entry;

  /// 1-based place in the queue.
  final int position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final since = entry.inQueueSince;
    final mono = AppTypography.mono(textTheme.bodySmall).copyWith(fontSize: 12);
    return GlassSurface.card(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      onTap: () => context.push(
        AppRoutes.jobDetail,
        extra: JenkinsJob(name: entry.taskName, url: entry.taskUrl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.raised,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '$position',
              semanticsLabel: 'Number $position',
              style: AppTypography.mono(
                textTheme.labelLarge,
              ).copyWith(color: t.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        Uri.decodeComponent(entry.taskName),
                        style: textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.stuck) ...[
                      const SizedBox(width: 8),
                      // Icon + text, never colour alone (NFR-A11Y-03).
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: t.unstable.foreground,
                      ),
                      Text(
                        ' Stuck',
                        style: textTheme.labelSmall?.copyWith(
                          color: t.unstable.foreground,
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.why case final why?) ...[
                  const SizedBox(height: 3),
                  Text(
                    why,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: entry.stuck
                          ? t.unstable.foreground
                          : t.textSecondary,
                    ),
                  ),
                ],
                if (since != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'in queue ${formatBuildDuration(DateTime.now().difference(since).inMilliseconds)}',
                    style: mono,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.cancel_outlined, color: t.failure.foreground),
            tooltip: 'Cancel ${entry.taskName}',
            onPressed: () => _confirmAndCancel(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Remove from queue?',
      message:
          "${entry.taskName} will not start. This may be someone else's "
          'build.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(queueNotifierProvider.notifier).cancel(entry);
  }
}
