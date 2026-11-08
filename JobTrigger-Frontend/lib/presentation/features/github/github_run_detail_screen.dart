import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/github/github_repo.dart';
import '../../../domain/github/github_workflow.dart';
import '../../../domain/github/github_workflow_run.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/status_pill.dart';
import '../../common_widgets/segment_row.dart';
import '../../common_widgets/section_label.dart';
import '../../../domain/github/github_job.dart';
import 'github_cancel_notifier.dart';
import 'github_jobs_notifier.dart';
import 'github_run_notifier.dart';
import 'github_run_polling_notifier.dart';
import 'github_runs_screen.dart' show toneForRunOutcome;

/// One run, live (`US-GH-RUN-03`) with a cancel action (`US-GH-RUN-04`).
/// Opened from the runs list with `(repo, workflow, run)`; [run] is shown
/// instantly while the first fetch lands, then the polled state takes over.
class GitHubRunDetailScreen extends ConsumerWidget {
  const GitHubRunDetailScreen({
    required this.repo,
    required this.workflow,
    required this.run,
    super.key,
  });

  final GitHubRepo repo;
  final GitHubWorkflow workflow;
  final GitHubWorkflowRun run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = repo.owner;
    final name = repo.name;
    // Keeps the 5s polling alive for as long as this screen is.
    ref.watch(gitHubRunPollingNotifierProvider(owner, name, run.id));
    final runAsync = ref.watch(gitHubRunNotifierProvider(owner, name, run.id));
    final current = runAsync.value ?? run;
    final jobsAsync = ref.watch(
      gitHubJobsNotifierProvider(owner, name, run.id),
    );
    final cancelRequested =
        ref.watch(gitHubCancelNotifierProvider(owner, name, run.id)).value ??
        false;
    final cancelling = cancelRequested && current.isActive;

    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final created = current.createdAt;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${repo.fullName} · ${workflow.name}',
                      style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text(
                        '#${current.runNumber} ${current.title}',
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        StatusPill(
                          label: cancelling ? 'Cancelling…' : current.label,
                          tone: cancelling
                              ? StatusTone.paused
                              : toneForRunOutcome(current.outcome),
                        ),
                        if (current.isActive) ...[
                          const SizedBox(width: 12),
                          const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      [
                        if (current.event.isNotEmpty) current.event,
                        if (current.branch != null) current.branch!,
                        if (created != null) relativeTime(created),
                      ].join(' · '),
                      style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                    ),
                    if (runAsync.hasError) ...[
                      const SizedBox(height: 16),
                      Text(
                        describeError(runAsync.error!),
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(
                              gitHubRunNotifierProvider(
                                owner,
                                name,
                                run.id,
                              ).notifier,
                            )
                            .refresh(),
                        child: const Text('Refresh'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const SectionLabel('Jobs'),
                    const SizedBox(height: 8),
                    _JobsSection(
                      jobsAsync: jobsAsync,
                      onRetry: () => ref
                          .read(
                            gitHubJobsNotifierProvider(
                              owner,
                              name,
                              run.id,
                            ).notifier,
                          )
                          .refresh(),
                    ),
                    if (current.isActive) ...[
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: cancelling
                            ? null
                            : () => _confirmCancel(context, ref, current),
                        child: Text(cancelling ? 'Cancelling…' : 'Cancel run'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    GitHubWorkflowRun current,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel run #${current.runNumber}?'),
        content: const Text(
          'GitHub will stop the run. This can take a few moments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep running'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel run'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(
          gitHubCancelNotifierProvider(repo.owner, repo.name, run.id).notifier,
        )
        .cancel(runNumber: current.runNumber);
  }
}

/// Each job as its own group — name, status pill, then its steps as the
/// shared segment bar (`US-GH-RUN-05`).
class _JobsSection extends StatelessWidget {
  const _JobsSection({required this.jobsAsync, required this.onRetry});

  final AsyncValue<List<GitHubJob>> jobsAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return jobsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            describeError(error),
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
      data: (jobs) {
        if (jobs.isEmpty) {
          return Text(
            'No jobs yet. They appear once GitHub starts the run.',
            style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final job in jobs)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            job.name,
                            style: textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusPill(
                          label: job.label,
                          tone: toneForRunOutcome(job.outcome),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (job.steps.isEmpty)
                      Text(
                        'No steps reported.',
                        style: textTheme.bodySmall?.copyWith(
                          color: t.textMuted,
                        ),
                      )
                    else
                      SegmentRow(
                        items: [
                          for (final step in job.steps)
                            SegmentItem(
                              label: step.name,
                              // Status in words, never colour alone.
                              semanticsLabel:
                                  'Step ${step.name}, ${step.label}',
                              color: t
                                  .status(toneForRunOutcome(step.outcome))
                                  .dot,
                              emphasis: switch (step.outcome) {
                                GitHubRunOutcome.running =>
                                  SegmentEmphasis.running,
                                GitHubRunOutcome.queued =>
                                  SegmentEmphasis.notRun,
                                _ => SegmentEmphasis.normal,
                              },
                            ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
