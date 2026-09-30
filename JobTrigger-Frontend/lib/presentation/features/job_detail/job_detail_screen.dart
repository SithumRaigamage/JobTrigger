import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/jenkins/build_artifact.dart';
import '../../../domain/jenkins/build_progress.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/parameter_values.dart';
import '../../../domain/jenkins/pending_input.dart';
import '../../../domain/jenkins/pipeline_stage.dart';
import '../../../domain/jenkins/queue_item.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../../domain/jenkins/scm_change.dart';
import '../../../domain/jenkins/test_report.dart';
import '../../../domain/jenkins/upstream_cause.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../home/pinned_jobs_notifier.dart';
import 'artifact_download_notifier.dart';
import 'build_status_polling_notifier.dart';
import 'cancel_build_notifier.dart';
import 'input_submit_notifier.dart';
import 'job_detail_notifier.dart';
import 'job_enabled_notifier.dart';
import 'parameter_edits_notifier.dart';
import 'parameter_files_notifier.dart';
import 'parameter_form.dart';
import 'pending_input_notifier.dart';
import 'pipeline_stages_notifier.dart';
import 'queue_status_notifier.dart';
import 'stage_detail_sheet.dart';
import 'stage_status_style.dart';
import 'test_report_notifier.dart';
import 'trigger_build_notifier.dart';

/// Ported from `JobDetailView.swift`/`JobDetailViewModel.swift`. [job] is
/// the (possibly stale, tree-fetched) job passed via navigation `extra` —
/// used as the family key and as a display fallback until the richer
/// detail fetch completes.
class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.job});

  final JenkinsJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobUrl = job.url;
    // Keeps the 5s poll-while-building loop alive for as long as this
    // screen is on screen; cancelled automatically when it's not (P5-06).
    ref.watch(buildStatusPollingNotifierProvider(jobUrl));
    // Watched here (not only in the body) so parameter edits survive for
    // the screen's lifetime, whatever the body is doing (AUD-18). Read
    // again at tap time, never captured here -- a closure built from this
    // frame's value could miss an edit made just before the tap.
    ref.watch(parameterEditsNotifierProvider(jobUrl));
    ref.watch(parameterFilesNotifierProvider(jobUrl));

    final jobAsync = ref.watch(jobDetailNotifierProvider(jobUrl));
    final isTriggering = ref
        .watch(triggerBuildNotifierProvider(jobUrl))
        .isLoading;
    final isCancelling = ref
        .watch(cancelBuildNotifierProvider(jobUrl))
        .isLoading;
    final queueItem = ref.watch(queueStatusNotifierProvider(jobUrl));
    final loadedJob = jobAsync.value;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(job.label),
        actions: [
          // US-JX-11: pin to the top of Home.
          IconButton(
            icon: Icon(
              ref.watch(
                    pinnedJobsNotifierProvider.select(
                      (pins) => pins.any((pin) => pin.url == job.url),
                    ),
                  )
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
            ),
            tooltip: 'Pin to Home',
            onPressed: () =>
                ref.read(pinnedJobsNotifierProvider.notifier).toggle(job),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => context.push(AppRoutes.jobHistory, extra: job),
          ),
          if (loadedJob != null && loadedJob.buildable != null)
            PopupMenuButton<bool>(
              tooltip: 'Job options',
              onSelected: (enable) =>
                  _confirmAndSetEnabled(context, ref, loadedJob, enable),
              itemBuilder: (context) => [
                // US-JX-13.
                PopupMenuItem(
                  value: !loadedJob.buildable!,
                  child: Text(
                    loadedJob.buildable! ? 'Disable job' : 'Enable job',
                  ),
                ),
              ],
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
                  formKey: jobUrl,
                  queueItem: queueItem,
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
          if (loadedJob != null)
            ResponsiveCenter(
              child: _ActionBar(
                job: loadedJob,
                isTriggering: isTriggering,
                isCancelling: isCancelling,
                onTrigger: () => _confirmAndTrigger(context, ref, loadedJob),
                onCancel:
                    (loadedJob.lastBuild != null &&
                        loadedJob.lastBuild!.building)
                    ? () => _confirmAndCancel(context, ref, loadedJob)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  /// AUD-08 / US-JOB-02/03: triggering has real side effects on a live
  /// system, so it's never a single accidental tap. The summary shows what
  /// will be sent, with secrets masked.
  Future<void> _confirmAndTrigger(
    BuildContext context,
    WidgetRef ref,
    JenkinsJob job,
  ) async {
    final values = effectiveParameterValues(
      job.parameterDefinitions,
      ref.read(parameterEditsNotifierProvider(job.url)),
    );
    final files = ref.read(parameterFilesNotifierProvider(job.url));
    final summary = parameterSummary(
      job.parameterDefinitions,
      values,
      files: files,
    );
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Trigger build?',
      message: 'Start a new build of ${job.label}.',
      confirmLabel: 'Trigger',
      details: summary.isEmpty ? null : _ParameterSummaryList(rows: summary),
    );
    if (!confirmed) return;
    await ref
        .read(triggerBuildNotifierProvider(job.url).notifier)
        .trigger(job: job, parameters: values, files: files);
  }

  /// US-JX-13: a state-changing admin action, so it asks first.
  Future<void> _confirmAndSetEnabled(
    BuildContext context,
    WidgetRef ref,
    JenkinsJob job,
    bool enable,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: enable ? 'Enable ${job.label}?' : 'Disable ${job.label}?',
      message: enable
          ? 'It can be built and triggered again.'
          : 'No new builds will start — manual, scheduled, or triggered — '
                "until it's enabled again. Running builds carry on.",
      confirmLabel: enable ? 'Enable' : 'Disable',
      destructive: !enable,
    );
    if (!confirmed) return;
    await ref
        .read(jobEnabledNotifierProvider(job.url).notifier)
        .setEnabled(enabled: enable, label: job.label);
  }

  /// AUD-08 / US-JOB-05.
  Future<void> _confirmAndCancel(
    BuildContext context,
    WidgetRef ref,
    JenkinsJob job,
  ) async {
    final build = job.lastBuild!;
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Cancel build #${build.number}?',
      message: 'This stops the running build of ${job.label}.',
      confirmLabel: 'Cancel build',
      destructive: true,
    );
    if (!confirmed) return;
    await ref
        .read(cancelBuildNotifierProvider(job.url).notifier)
        .cancel(buildUrl: build.url, buildNumber: build.number);
  }
}

/// The parameter values a trigger will send, as shown in its confirmation.
class _ParameterSummaryList extends StatelessWidget {
  const _ParameterSummaryList({required this.rows});

  final List<ParameterSummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${row.name}: ',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: row.display, style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
      ],
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
                  onPressed: isTriggering || job.buildable == false
                      ? null
                      : onTrigger,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    job.buildable == false
                        ? 'Disabled'
                        : isTriggering
                        ? 'Triggering…'
                        : 'Trigger Build',
                  ),
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
    required this.formKey,
    required this.queueItem,
    required this.onViewLog,
  });

  final JenkinsJob job;

  /// `ParameterEditsNotifier` key for this job's trigger form.
  final String formKey;
  final QueueItem? queueItem;
  final VoidCallback? onViewLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parameterDefinitions = job.parameterDefinitions;
    final parameterValues = effectiveParameterValues(
      parameterDefinitions,
      ref.watch(parameterEditsNotifierProvider(formKey)),
    );
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
        if (job.buildable == false) ...[
          const _DisabledBanner(),
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
            values: parameterValues,
            onChanged: ref
                .read(parameterEditsNotifierProvider(formKey).notifier)
                .setValue,
            files: ref.watch(parameterFilesNotifierProvider(formKey)),
            onPickFile: (name) => pickParameterFile(ref, formKey, name),
            onRemoveFile: ref
                .read(parameterFilesNotifierProvider(formKey).notifier)
                .remove,
          ),
        ],
      ],
    );
  }
}

/// US-PIPE-05: the highest-visibility card on the screen while present —
/// this can directly gate a production deployment (see `pending_input
/// .dart`'s doc comment). Approve/reject both require confirmation, same
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
  String get _formKey => 'input:${widget.buildUrl}#${widget.input.id}';

  @override
  Widget build(BuildContext context) {
    final parameterValues = effectiveParameterValues(
      widget.input.inputs,
      ref.watch(parameterEditsNotifierProvider(_formKey)),
    );
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
                values: parameterValues,
                onChanged: ref
                    .read(parameterEditsNotifierProvider(_formKey).notifier)
                    .setValue,
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
    // Read at tap time, not captured at build (see `_confirmAndTrigger`).
    final values = effectiveParameterValues(
      widget.input.inputs,
      ref.read(parameterEditsNotifierProvider(_formKey)),
    );
    final confirmed = await showConfirmationDialog(
      context,
      title: proceed ? widget.input.proceedText : widget.input.abortText,
      message: proceed
          ? 'This will resume the paused pipeline. Are you sure?'
          : 'This will abort the paused pipeline. Are you sure?',
      confirmLabel: proceed ? widget.input.proceedText : widget.input.abortText,
      destructive: !proceed,
      details: proceed && widget.input.inputs.isNotEmpty
          ? _ParameterSummaryList(
              rows: parameterSummary(widget.input.inputs, values),
            )
          : null,
    );
    if (!confirmed || !context.mounted) return;

    await ref
        .read(inputSubmitNotifierProvider(widget.buildUrl).notifier)
        .submit(
          jobUrl: widget.jobUrl,
          inputId: widget.input.id,
          proceed: proceed,
          parameters: proceed ? values : const {},
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
            _BuildLinks(job: job),
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
              _StageChipRow(
                buildUrl: lastBuild.url,
                stages: pipelineStages!,
                onViewLog: onViewLog,
              ),
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

/// US-JX-05: one-tap links to the last successful and last failed build,
/// shown only when they aren't simply the last build again.
class _BuildLinks extends StatelessWidget {
  const _BuildLinks({required this.job});

  final JenkinsJob job;

  @override
  Widget build(BuildContext context) {
    final lastNumber = job.lastBuild?.number;
    final links = [
      if (job.lastSuccessfulBuild case final build?
          when build.number != lastNumber)
        (build: build, label: 'Last success', icon: Icons.check_circle),
      if (job.lastFailedBuild case final build? when build.number != lastNumber)
        (build: build, label: 'Last failure', icon: Icons.cancel),
    ];
    if (links.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final link in links)
            ActionChip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                link.icon,
                size: 16,
                color: AppColors.forBuildResult(link.build.result),
              ),
              label: Text(
                '${link.label} #${link.build.number} · '
                '${relativeTime(fromJenkinsTimestamp(link.build.timestamp))}',
              ),
              onPressed: () =>
                  context.push(AppRoutes.buildLog, extra: link.build),
            ),
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

/// US-PIPE-04 / US-JX-04: one chip per stage, with parallel branches
/// folded into their parent (`groupParallelStages`). Tapping a chip opens
/// that stage's steps and logs.
class _StageChipRow extends StatelessWidget {
  const _StageChipRow({
    required this.buildUrl,
    required this.stages,
    required this.onViewLog,
  });

  final String buildUrl;
  final List<PipelineStage> stages;
  final VoidCallback? onViewLog;

  @override
  Widget build(BuildContext context) {
    final nodes = groupParallelStages(stages);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: nodes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final node = nodes[index];
          return ActionChip(
            avatar: Icon(
              iconForStageStatus(node.status),
              size: 16,
              color: colorForStageStatus(node.status),
            ),
            // Status is conveyed by icon shape + this label text, not
            // color alone (NFR-A11Y-03).
            label: Text(
              node.branches.isEmpty
                  ? node.stage.name
                  : '${node.stage.name} ⫽${node.branches.length}',
            ),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (sheetContext) => StageDetailSheet(
                buildUrl: buildUrl,
                node: node,
                onViewFullLog: onViewLog == null
                    ? null
                    : () {
                        Navigator.of(sheetContext).pop();
                        onViewLog!();
                      },
              ),
            ),
          );
        },
      ),
    );
  }
}

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
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FailingTestsSheet(report: report),
    );
  }
}

/// US-JX-08: every failing test, expandable to its message and a
/// copyable stack trace. New failures (a regression, or failing for the
/// first time) are badged and listed first.
class FailingTestsSheet extends StatelessWidget {
  const FailingTestsSheet({super.key, required this.report});

  final TestReport report;

  @override
  Widget build(BuildContext context) {
    final tests = [...report.failingTests]
      ..sort((a, b) => (b.isNewFailure ? 1 : 0) - (a.isNewFailure ? 1 : 0));
    final hidden = report.failCount - tests.length;
    final textTheme = Theme.of(context).textTheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            '${report.failCount} failing test${report.failCount == 1 ? '' : 's'}',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final test in tests) _FailingTestTile(test: test),
          if (hidden > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '$hidden more not shown — see the full test report in Jenkins.',
                style: textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _FailingTestTile extends StatelessWidget {
  const _FailingTestTile({required this.test});

  final FailingTest test;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trace = test.stackTrace;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.cancel,
        color: AppColors.buildFailure,
        size: 20,
      ),
      title: Text(test.name),
      subtitle: Text(
        [if (test.isNewFailure) 'New failure', ?test.className].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        if (test.errorDetails case final details? when details.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText(details, style: textTheme.bodyMedium),
            ),
          ),
        if (trace != null && trace.isNotEmpty) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                trace,
                style: AppTypography.buildLog.copyWith(color: Colors.white),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy stack trace'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: trace));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stack trace copied')),
                  );
                }
              },
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
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

/// US-JX-13: why Trigger is off.
class _DisabledBanner extends StatelessWidget {
  const _DisabledBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.block, semanticLabel: 'Disabled'),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This job is disabled. Enable it from the menu to build it.',
            ),
          ),
        ],
      ),
    );
  }
}
