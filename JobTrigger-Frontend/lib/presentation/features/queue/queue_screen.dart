import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/queue_entry.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/status_indicator.dart';
import '../../navigation/app_routes.dart';
import 'queue_notifier.dart';

/// US-JX-09: everything waiting for an executor, why it's waiting, and a
/// way to cancel an item. Refreshes every 5 s while open.
class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueNotifierProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Build queue')),
      body: ResponsiveCenter(
        child: queue.when(
          skipLoadingOnRefresh: true,
          data: (items) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(queueNotifierProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
                16,
                16,
              ),
              children: [
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text(
                        'Nothing is waiting',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                for (final item in items) ...[
                  _QueueTile(entry: item),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: ConnectionErrorView(
              message: describeError(error),
              onRetry: () => ref.invalidate(queueNotifierProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _QueueTile extends ConsumerWidget {
  const _QueueTile({required this.entry});

  final QueueEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final since = entry.inQueueSince;
    return GlassSurface.card(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      onTap: () => context.push(
        AppRoutes.jobDetail,
        extra: JenkinsJob(name: entry.taskName, url: entry.taskUrl),
      ),
      child: Row(
        children: [
          StatusIndicator(color: entry.taskColor),
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
                        style: textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.stuck) ...[
                      const SizedBox(width: 8),
                      // Icon + text, never color alone (NFR-A11Y-03).
                      const Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: AppColors.buildUnstable,
                      ),
                      Text(' Stuck', style: textTheme.labelSmall),
                    ],
                  ],
                ),
                if (since != null)
                  Text(
                    'waiting ${relativeTime(since).replaceAll(' ago', '')}',
                    style: textTheme.labelSmall,
                  ),
                if (entry.why case final why?)
                  Text(
                    why,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
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
