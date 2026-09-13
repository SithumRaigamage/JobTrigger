import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import 'history_tile.dart';
import 'job_history_notifier.dart';

/// Ported from `HistoryView.swift`. Reuses `HistoryTile` (P5-16) — the same
/// widget `GlobalHistoryScreen` uses, just without a job name prefix.
class JobHistoryScreen extends ConsumerWidget {
  const JobHistoryScreen({super.key, required this.job});

  final JenkinsJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(jobHistoryNotifierProvider(job.url));

    return Scaffold(
      appBar: AppBar(title: Text('${job.name} History')),
      body: ResponsiveCenter(
        child: historyAsync.when(
          data: (builds) {
            if (builds.isEmpty) {
              return const Center(child: Text('No build history yet'));
            }
            return RefreshIndicator(
              onRefresh: () => ref
                  .read(jobHistoryNotifierProvider(job.url).notifier)
                  .refresh(),
              child: ListView.builder(
                itemCount: builds.length,
                itemBuilder: (context, index) {
                  final build = builds[index];
                  return HistoryTile(
                    key: ValueKey(build.number),
                    jenkinsBuild: build,
                    onTap: () =>
                        context.push(AppRoutes.buildLog, extra: build),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: ConnectionErrorView(
              message: describeError(error),
              onRetry: () => ref
                  .read(jobHistoryNotifierProvider(job.url).notifier)
                  .refresh(),
            ),
          ),
        ),
      ),
    );
  }
}
