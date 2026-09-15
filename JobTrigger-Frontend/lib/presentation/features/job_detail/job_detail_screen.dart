import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/jenkins/build_artifact.dart';
import '../../../domain/jenkins/build_progress.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/parameter_definition.dart';
import '../../../domain/jenkins/pending_input.dart';
import '../../../domain/jenkins/pipeline_stage.dart';
import '../../../domain/jenkins/queue_item.dart';
import '../../../domain/jenkins/scm_change.dart';
import '../../../domain/jenkins/test_report.dart';
import '../../../domain/jenkins/upstream_cause.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import 'artifact_download_notifier.dart';
import 'build_status_polling_notifier.dart';
import 'cancel_build_notifier.dart';
import 'input_submit_notifier.dart';
import 'job_detail_notifier.dart';
import 'parameter_form.dart';
import 'pending_input_notifier.dart';
import 'pipeline_stages_notifier.dart';
import 'queue_status_notifier.dart';
import 'test_report_notifier.dart';
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
    final queueItem = ref.watch(queueStatusNotifierProvider(jobUrl));
    final job = jobAsync.value;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
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
      // Trigger/Cancel are pinned outside the scrollable body (not the
      // ListView's last items) so they're always reachable without
      // scrolling, regardless of how much variable content (stages, test
      // report, parameters, changes) a given job has above them.
      body: Column(
        children: [
          Expanded(
            child: ResponsiveCenter(
              child: jobAsync.when(
                data: (job) => _JobDetailBody(
                  job: job,
                  queueItem: queueItem,
                  onParametersChanged: (values) => _parameterValues = values,
                  onViewLog: job.lastBuild == null
                      ? null
                      : () => context.push(
                          AppRoutes.buildLog,
                          extra: job.lastBuild,
                        ),
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
          ),
          if (job != null)
            ResponsiveCenter(
              child: _ActionBar(
                job: job,
                isTriggering: isTriggering,
                isCancelling: isCancelling,
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
              ),
            ),
        ],
      ),
    );
  }
}

/// Fixed action bar pinned below the scrollable body — see the "don't make
/// the user scroll to find Trigger Build" comment above.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.job,
    required this.isTriggering,
    required this.isCancelling,
    required this.onTrigger,
    required this.onCancel,
  });

  final JenkinsJob job;
  final bool isTriggering;
  final bool isCancelling;
  final VoidCallback onTrigger;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (onCancel != null) ...[
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: isCancelling ? null : onCancel,
                    icon: const Icon(Icons.stop_circle),
                    label: Text(isCancelling ? 'Cancelling…' : 'Cancel Build'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: isTriggering ? null : onTrigger,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(isTriggering ? 'Triggering…' : 'Trigger Build'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobDetailBody extends ConsumerWidget {
  const _JobDetailBody({
    required this.job,
    required this.queueItem,
    required this.onParametersChanged,
    required this.onViewLog,
  });

  final JenkinsJob job;
  final QueueItem? queueItem;
  final ValueChanged<Map<String, String>> onParametersChanged;
  final VoidCallback? onViewLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parameterDefinitions = job.property
        .expand(
          (prop) => prop.parameterDefinitions ?? const <ParameterDefinition>[],
        )
        .toList();
    final testReport = job.lastBuild == null
        ? null
        : ref.watch(testReportNotifierProvider(job.lastBuild!.url)).value;
    final pipelineStages = job.lastBuild == null
        ? null
        : ref.watch(pipelineStagesNotifierProvider(job.lastBuild!.url)).value;
    final pendingInput = job.lastBuild == null
        ? null
        : ref.watch(pendingInputNotifierProvider(job.lastBuild!.url)).value;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
        16,
        16,
      ),
      children: [
        // Highest-visibility position in the layout, per the story's own
        // design note — this is the single most action-relevant thing a
        // user could open this screen to see.
        if (pendingInput != null) ...[
          _PendingInputBanner(
            jobUrl: job.url,
            buildUrl: job.lastBuild!.url,
            input: pendingInput,
          ),
          const SizedBox(height: 16),
        ],
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
        if (queueItem != null) ...[
          _QueuedCard(queueItem: queueItem!),
          const SizedBox(height: 16),
        ],
        _LastBuildCard(
          job: job,
          testReport: testReport,
          pipelineStages: pipelineStages,
          onViewLog: onViewLog,
        ),
        if (parameterDefinitions.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Parameters', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ParameterForm(
            parameters: parameterDefinitions,
            onChanged: onParametersChanged,
          ),
        ],
      ],
    );
  }
}

/// US-PIPE-05: the highest-visibility card on the screen while present —
/// this can directly gate a production deployment (see `pending_input
/// .dart`'s doc comment on why this endpoint is unverified against a real
/// paused pipeline). Approve/reject both require confirmation, same
/// rationale as `US-JOB-02`/`US-JOB-05`'s trigger/cancel confirmations.
class _PendingInputBanner extends ConsumerStatefulWidget {
  const _PendingInputBanner({
    required this.jobUrl,
    required this.buildUrl,
    required this.input,
  });

  final String jobUrl;
  final String buildUrl;
  final PendingInput input;

  @override
  ConsumerState<_PendingInputBanner> createState() =>
      _PendingInputBannerState();
}

class _PendingInputBannerState extends ConsumerState<_PendingInputBanner> {
  Map<String, String> _parameterValues = const {};

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref
        .watch(inputSubmitNotifierProvider(widget.buildUrl))
        .isLoading;

    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pause_circle,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.input.message ?? 'Waiting for your approval',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.input.inputs.isNotEmpty) ...[
              const SizedBox(height: 12),
              ParameterForm(
                parameters: widget.input.inputs,
                onChanged: (values) => _parameterValues = values,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: isSubmitting
                      ? null
                      : () => _confirmAndSubmit(context, proceed: false),
                  child: Text(widget.input.abortText),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () => _confirmAndSubmit(context, proceed: true),
                  child: Text(
                    isSubmitting ? 'Submitting…' : widget.input.proceedText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndSubmit(
    BuildContext context, {
    required bool proceed,
  }) async {
    final actionLabel = proceed
        ? widget.input.proceedText
        : widget.input.abortText;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(actionLabel),
        content: Text(
          proceed
              ? 'This will resume the paused pipeline. Are you sure?'
              : 'This will abort the paused pipeline. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(inputSubmitNotifierProvider(widget.buildUrl).notifier)
        .submit(
          jobUrl: widget.jobUrl,
          inputId: widget.input.id,
          proceed: proceed,
          parameters: _parameterValues,
        );
  }
}

/// US-PIPE-01: shown between trigger and the existing "building" state
/// (`_LastBuildCard`) while a just-triggered build is still waiting for an
/// executor, distinct from both "not building" and "building" so a queued
/// build never reads as "my tap did nothing."
class _QueuedCard extends StatelessWidget {
  const _QueuedCard({required this.queueItem});

  final QueueItem queueItem;

  @override
  Widget build(BuildContext context) {
    return GlassSurface.card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              queueItem.why ?? 'Queued — waiting for an executor',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _LastBuildCard extends StatelessWidget {
  const _LastBuildCard({
    required this.job,
    required this.testReport,
    required this.pipelineStages,
    required this.onViewLog,
  });

  final JenkinsJob job;
  final TestReport? testReport;
  final List<PipelineStage>? pipelineStages;
  final VoidCallback? onViewLog;

  @override
  Widget build(BuildContext context) {
    final lastBuild = job.lastBuild;
    return GlassSurface.card(
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
            if (lastBuild.causes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                lastBuild.causes.join(', '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (lastBuild.upstreamCause != null) ...[
              const SizedBox(height: 4),
              _UpstreamLink(cause: lastBuild.upstreamCause!),
            ],
            if (lastBuild.changes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ChangesList(changes: lastBuild.changes),
            ],
            if (pipelineStages != null && pipelineStages!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _StageChipRow(stages: pipelineStages!, onTap: onViewLog),
            ],
            if (testReport != null) ...[
              const SizedBox(height: 8),
              _TestReportChip(report: testReport!),
            ],
            if (lastBuild.artifacts.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ArtifactsList(
                buildUrl: lastBuild.url,
                artifacts: lastBuild.artifacts,
              ),
            ],
            if (lastBuild.building) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: BuildProgress.ratioFor(lastBuild)),
            ],
          ],
          // Job-level, not build-level -- shown regardless of whether
          // this job has ever built (unlike everything else on this
          // card, which lives inside the `lastBuild != null` branch
          // above).
          if (job.downstreamProjects.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Downstream', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final downstream in job.downstreamProjects)
                  ActionChip(
                    label: Text(downstream.name),
                    onPressed: () => context.push(
                      AppRoutes.jobDetail,
                      extra: JenkinsJob(
                        name: downstream.name,
                        url: downstream.url,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// US-PIPE-09: the upstream job/build that caused this one, when known —
/// tappable through to that job's detail (reuses `US-JOB-01`'s existing
/// `NotFoundFailure` handling if it's since been deleted/renamed, no new
/// error handling needed).
class _UpstreamLink extends StatelessWidget {
  const _UpstreamLink({required this.cause});

  final UpstreamCause cause;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(
        AppRoutes.jobDetail,
        extra: JenkinsJob(name: cause.projectName, url: cause.url),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_upward,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            cause.projectName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

/// US-PIPE-04: a horizontally scrollable stage chip row. Tapping any chip
/// opens the full console log (reuses `onViewLog`) rather than scrolling
/// to that stage's exact log position — Jenkins' per-node log endpoint is
/// a genuinely different mechanism from the progressive-text log already
/// used everywhere else in this app, scoped out of this pass; flagged as
/// a real, deliberate gap rather than attempted half-done.
class _StageChipRow extends StatelessWidget {
  const _StageChipRow({required this.stages, required this.onTap});

  final List<PipelineStage> stages;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stages.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final stage = stages[index];
          return ActionChip(
            avatar: Icon(
              _iconForStageStatus(stage.status),
              size: 16,
              color: _colorForStageStatus(stage.status),
            ),
            // Status is conveyed by icon shape + this label text, not
            // color alone (NFR-A11Y-03).
            label: Text(stage.name),
            onPressed: onTap,
          );
        },
      ),
    );
  }
}

/// Jenkins' pipeline stage `status` uses a different vocabulary than a
/// build's classic `result` field (`FAILED` here vs `FAILURE` on
/// `AppColors.forBuildResult`, plus pipeline-only states), so this can't
/// reuse that mapping directly.
Color _colorForStageStatus(String status) => switch (status.toUpperCase()) {
  'SUCCESS' => AppColors.buildSuccess,
  'FAILED' => AppColors.buildFailure,
  'UNSTABLE' => AppColors.buildUnstable,
  'IN_PROGRESS' => Colors.blue,
  'PAUSED_PENDING_INPUT' => Colors.amber,
  _ => AppColors.buildAborted, // NOT_EXECUTED, ABORTED, unrecognized.
};

IconData _iconForStageStatus(String status) => switch (status.toUpperCase()) {
  'SUCCESS' => Icons.check_circle,
  'FAILED' => Icons.cancel,
  'IN_PROGRESS' => Icons.autorenew,
  'PAUSED_PENDING_INPUT' => Icons.pause_circle,
  'NOT_EXECUTED' => Icons.circle_outlined,
  _ => Icons.circle,
};

/// US-PIPE-06: a compact pass/fail/skip summary; tapping it when there are
/// failures shows the failing test names (a summary list, not full
/// stack traces/output — those stay in the console log, US-LOG-01).
class _TestReportChip extends StatelessWidget {
  const _TestReportChip({required this.report});

  final TestReport report;

  @override
  Widget build(BuildContext context) {
    final hasFailures = report.failCount > 0;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: hasFailures ? () => _showFailingTests(context) : null,
      child: Chip(
        // Count pairs with text, not color alone (NFR-A11Y-03) -- the
        // numbers themselves already convey pass/fail/skip.
        label: Text(
          '${report.passCount} passed · ${report.failCount} failed · '
          '${report.skipCount} skipped',
        ),
        backgroundColor: hasFailures
            ? AppColors.buildFailure.withValues(alpha: 0.15)
            : null,
      ),
    );
  }

  void _showFailingTests(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            Text(
              'Failing tests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final test in report.failingTests)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(test),
              ),
          ],
        ),
      ),
    );
  }
}

/// US-PIPE-07: list-and-share, not an in-app file manager or on-device
/// download flow — see `ArtifactDownloadNotifier`'s doc comment for why
/// this goes through the OS share sheet rather than a bare link.
class _ArtifactsList extends StatelessWidget {
  const _ArtifactsList({required this.buildUrl, required this.artifacts});

  final String buildUrl;
  final List<BuildArtifact> artifacts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final artifact in artifacts)
          _ArtifactRow(buildUrl: buildUrl, artifact: artifact),
      ],
    );
  }
}

class _ArtifactRow extends ConsumerWidget {
  const _ArtifactRow({required this.buildUrl, required this.artifact});

  final String buildUrl;
  final BuildArtifact artifact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDownloading = ref
        .watch(artifactDownloadNotifierProvider(artifact.relativePath))
        .isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              artifact.fileName,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isDownloading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.ios_share, size: 18),
              tooltip: 'Share ${artifact.fileName}',
              visualDensity: VisualDensity.compact,
              onPressed: () => ref
                  .read(
                    artifactDownloadNotifierProvider(
                      artifact.relativePath,
                    ).notifier,
                  )
                  .download(buildUrl: buildUrl, artifact: artifact),
            ),
        ],
      ),
    );
  }
}

/// US-PIPE-03: collapsed to the first 3 changes past that count, so a
/// large commit batch doesn't push the trigger button off-screen.
class _ChangesList extends StatefulWidget {
  const _ChangesList({required this.changes});

  final List<ScmChange> changes;

  @override
  State<_ChangesList> createState() => _ChangesListState();
}

class _ChangesListState extends State<_ChangesList> {
  static const _collapsedLimit = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final overflow = widget.changes.length - _collapsedLimit;
    final visible = _expanded || overflow <= 0
        ? widget.changes
        : widget.changes.take(_collapsedLimit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final change in visible)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${change.author}: ${change.message}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (overflow > 0)
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Show less' : 'Show $overflow more'),
          ),
      ],
    );
  }
}
