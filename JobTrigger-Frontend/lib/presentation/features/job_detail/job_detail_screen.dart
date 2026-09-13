import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/jenkins/build_progress.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/parameter_definition.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import 'build_status_polling_notifier.dart';
import 'cancel_build_notifier.dart';
import 'job_detail_notifier.dart';
import 'parameter_form.dart';
import 'trigger_build_notifier.dart';

/// Ported from `JobDetailView.swift`/`JobDetailViewModel.swift`. [job] is
/// the (possibly stale, tree-fetched) job passed via navigation `extra` —
/// used as the family key and as a display fallback until the richer
/// detail fetch completes.
class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.job});

  final JenkinsJob job;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  Map<String, String> _parameterValues = const {};

  @override
  Widget build(BuildContext context) {
    final jobUrl = widget.job.url;
    // Keeps the 5s poll-while-building loop alive for as long as this
    // screen is on screen; cancelled automatically when it's not (P5-06).
    ref.watch(buildStatusPollingNotifierProvider(jobUrl));

    final jobAsync = ref.watch(jobDetailNotifierProvider(jobUrl));
    final isTriggering = ref
        .watch(triggerBuildNotifierProvider(jobUrl))
        .isLoading;
    final isCancelling = ref
        .watch(cancelBuildNotifierProvider(jobUrl))
        .isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () =>
                context.push(AppRoutes.jobHistory, extra: widget.job),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: jobAsync.when(
          data: (job) => _JobDetailBody(
            job: job,
            isTriggering: isTriggering,
            isCancelling: isCancelling,
            onParametersChanged: (values) => _parameterValues = values,
            onTrigger: () => ref
                .read(triggerBuildNotifierProvider(jobUrl).notifier)
                .trigger(job: job, parameters: _parameterValues),
            onCancel: (job.lastBuild != null && job.lastBuild!.building)
                ? () => ref
                      .read(cancelBuildNotifierProvider(jobUrl).notifier)
                      .cancel(
                        buildUrl: job.lastBuild!.url,
                        buildNumber: job.lastBuild!.number,
                      )
                : null,
            onViewLog: job.lastBuild == null
                ? null
                : () => context.push(AppRoutes.buildLog, extra: job.lastBuild),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: ConnectionErrorView(
              message: describeError(error),
              onRetry: () => ref
                  .read(jobDetailNotifierProvider(jobUrl).notifier)
                  .refresh(),
            ),
          ),
        ),
      ),
    );
  }
}

class _JobDetailBody extends StatelessWidget {
  const _JobDetailBody({
    required this.job,
    required this.isTriggering,
    required this.isCancelling,
    required this.onParametersChanged,
    required this.onTrigger,
    required this.onCancel,
    required this.onViewLog,
  });

  final JenkinsJob job;
  final bool isTriggering;
  final bool isCancelling;
  final ValueChanged<Map<String, String>> onParametersChanged;
  final VoidCallback onTrigger;
  final VoidCallback? onCancel;
  final VoidCallback? onViewLog;

  @override
  Widget build(BuildContext context) {
    final parameterDefinitions = job.property
        .expand(
          (prop) => prop.parameterDefinitions ?? const <ParameterDefinition>[],
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (job.description != null && job.description!.isNotEmpty) ...[
          Text(job.description!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
        ],
        if (job.healthReport.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final report in job.healthReport)
                Chip(
                  label: Text(
                    '${report.description ?? 'Health'} (${report.score ?? '?'}%)',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _LastBuildCard(job: job, onViewLog: onViewLog),
        if (job.lastBuild != null && job.lastBuild!.building) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: isCancelling ? null : onCancel,
            icon: const Icon(Icons.stop_circle),
            label: Text(isCancelling ? 'Cancelling…' : 'Cancel Build'),
          ),
        ],
        if (parameterDefinitions.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Parameters', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ParameterForm(
            parameters: parameterDefinitions,
            onChanged: onParametersChanged,
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: isTriggering ? null : onTrigger,
          icon: const Icon(Icons.play_arrow),
          label: Text(isTriggering ? 'Triggering…' : 'Trigger Build'),
        ),
      ],
    );
  }
}

class _LastBuildCard extends StatelessWidget {
  const _LastBuildCard({required this.job, required this.onViewLog});

  final JenkinsJob job;
  final VoidCallback? onViewLog;

  @override
  Widget build(BuildContext context) {
    final lastBuild = job.lastBuild;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastBuild == null)
              const Text('No builds yet')
            else ...[
              Row(
                children: [
                  Icon(
                    lastBuild.building ? Icons.autorenew : Icons.circle,
                    size: 16,
                    color: AppColors.forBuildResult(lastBuild.result),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lastBuild.building
                        ? 'Building #${lastBuild.number}…'
                        : '#${lastBuild.number} ${lastBuild.result ?? ''}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  if (onViewLog != null)
                    TextButton(
                      onPressed: onViewLog,
                      child: const Text('View Log'),
                    ),
                ],
              ),
              if (lastBuild.building) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: BuildProgress.ratioFor(lastBuild),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
