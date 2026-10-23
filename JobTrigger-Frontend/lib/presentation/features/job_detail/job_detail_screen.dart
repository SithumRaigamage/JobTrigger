import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/jenkins/build_progress.dart';
import '../../../domain/jenkins/build_watch.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/parameter_values.dart';
import '../../../domain/jenkins/pending_input.dart';
import '../../../domain/jenkins/pipeline_stage.dart';
import '../../../domain/jenkins/queue_item.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../../domain/jenkins/test_report.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../../core/theme/app_typography.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/section_label.dart';
import '../../common_widgets/status_pill.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../home/pinned_jobs_notifier.dart';
import '../notifications/build_watch_notifier.dart';
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
import 'build_sections.dart';
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

    final pinned = ref.watch(
      pinnedJobsNotifierProvider.select(
        (pins) => pins.any((pin) => pin.url == job.url),
      ),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.schedule_outlined),
                      tooltip: 'History',
                      onPressed: () =>
                          context.push(AppRoutes.jobHistory, extra: job),
                    ),
                    if (loadedJob != null) _WatchMenu(job: loadedJob),
                    // US-JX-11: pin to the top of Home.
                    IconButton(
                      icon: Icon(
                        pinned ? Icons.push_pin : Icons.push_pin_outlined,
                        color: pinned
                            ? AppTokens.of(context).running.foreground
                            : null,
                      ),
                      tooltip: pinned ? 'Unpin from Home' : 'Pin to Home',
                      onPressed: () => ref
                          .read(pinnedJobsNotifierProvider.notifier)
                          .toggle(job),
                    ),
                    if (loadedJob != null && loadedJob.buildable != null)
                      PopupMenuButton<bool>(
                        tooltip: 'Job options',
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (enable) => _confirmAndSetEnabled(
                          context,
                          ref,
                          loadedJob,
                          enable,
                        ),
                        itemBuilder: (context) => [
                          // US-JX-13.
                          PopupMenuItem(
                            value: !loadedJob.buildable!,
                            child: Text(
                              loadedJob.buildable!
                                  ? 'Disable job'
                                  : 'Enable job',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // Trigger/Cancel are pinned outside the scrollable body (not
            // the list's last items) so they're always reachable without
            // scrolling, however much a job shows above them.
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
              _ActionBar(
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
          ],
        ),
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
    final t = AppTokens.of(context);
    final label = job.buildable == false
        ? 'Disabled'
        : isTriggering
        ? 'Triggering…'
        : job.parameterDefinitions.isEmpty
        ? 'Trigger build'
        : 'Build with parameters';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.background,
        border: Border(top: BorderSide(color: t.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: ResponsiveCenter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                if (onCancel != null) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.failure.foreground,
                      side: BorderSide(color: t.failure.dot),
                      minimumSize: const Size(64, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: isCancelling ? null : onCancel,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(isCancelling ? 'Stopping…' : 'Stop'),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: isTriggering || job.buildable == false
                        ? null
                        : onTrigger,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(label),
                  ),
                ),
              ],
            ),
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

    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        Semantics(
          header: true,
          child: Text(job.label, style: textTheme.headlineMedium),
        ),
        if (job.description != null && job.description!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            job.description!,
            style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
          ),
        ],
        const SizedBox(height: 16),
        // Highest-visibility position in the layout, per the story's own
        // design note — this is the single most action-relevant thing a
        // user could open this screen to see.
        if (pendingInput != null) ...[
          _PendingInputBanner(
            jobUrl: job.url,
            buildUrl: job.lastBuild!.url,
            input: pendingInput,
          ),
          const SizedBox(height: 14),
        ],
        if (job.buildable == false) ...[
          const _DisabledBanner(),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
        ],
        if (queueItem != null) ...[
          _QueuedCard(queueItem: queueItem!),
          const SizedBox(height: 14),
        ],
        _LastBuildCard(
          job: job,
          testReport: testReport,
          pipelineStages: pipelineStages,
          onViewLog: onViewLog,
        ),
        if (parameterDefinitions.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionLabel('Parameters'),
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
        // Job-level, not build-level -- shown whether or not this job has
        // ever built.
        if (job.downstreamProjects.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionLabel('Downstream'),
          const SizedBox(height: 10),
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

    final paused = AppTokens.of(context).paused;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paused.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pause_circle_outline_rounded,
                  color: paused.foreground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.input.message ?? 'Waiting for your approval',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: paused.foreground),
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
    final textTheme = Theme.of(context).textTheme;
    if (lastBuild == null) {
      return GlassSurface.card(
        padding: const EdgeInsets.all(16),
        child: Text('No builds yet', style: textTheme.bodyMedium),
      );
    }
    final duration = lastBuild.duration;
    // While it builds, how long it has been running.
    final elapsed = lastBuild.building
        ? DateTime.now().millisecondsSinceEpoch - lastBuild.timestamp
        : duration;
    final line = [
      '#${lastBuild.number}',
      if (elapsed != null && elapsed > 0) formatBuildDuration(elapsed),
    ].join(' · ');
    return GlassSurface.card(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      onTap: () => context.push(AppRoutes.buildDetail, extra: lastBuild),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill.forBuildResult(
                lastBuild.building ? null : lastBuild.result,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.mono(textTheme.bodyMedium),
                ),
              ),
              if (onViewLog != null)
                TextButton.icon(
                  onPressed: onViewLog,
                  icon: const Icon(Icons.terminal_rounded, size: 18),
                  label: const Text('Log'),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pipelineStages != null && pipelineStages!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  StageChipRow(
                    buildUrl: lastBuild.url,
                    stages: pipelineStages!,
                    onViewLog: onViewLog,
                  ),
                ] else if (lastBuild.building) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: BuildProgress.ratioFor(lastBuild),
                      semanticsLabel: 'Build progress',
                    ),
                  ),
                ],
                _BuildLinks(job: job),
                if (lastBuild.causes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(lastBuild.causes.join(', '), style: textTheme.bodySmall),
                ],
                if (lastBuild.upstreamCause != null) ...[
                  const SizedBox(height: 4),
                  UpstreamLink(cause: lastBuild.upstreamCause!),
                ],
                if (lastBuild.changes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ChangesList(changes: lastBuild.changes),
                ],
                if (testReport != null) ...[
                  const SizedBox(height: 8),
                  TestReportChip(report: testReport!),
                ],
                if (lastBuild.artifacts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ArtifactsList(
                    buildUrl: lastBuild.url,
                    artifacts: lastBuild.artifacts,
                  ),
                ],
              ],
            ),
          ),
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
                color: AppTokens.of(
                  context,
                ).status(AppColors.toneForBuildResult(link.build.result)).dot,
              ),
              label: Text(
                '${link.label} #${link.build.number} · '
                '${relativeTime(fromJenkinsTimestamp(link.build.timestamp))}',
              ),
              onPressed: () =>
                  context.push(AppRoutes.buildDetail, extra: link.build),
            ),
        ],
      ),
    );
  }
}

/// US-JX-13: why Trigger is off.
class _DisabledBanner extends StatelessWidget {
  const _DisabledBanner();

  @override
  Widget build(BuildContext context) => const InlineAlert(
    tone: StatusTone.neutral,
    icon: Icons.block_rounded,
    message: 'This job is disabled. Enable it from the menu to build it.',
  );
}

/// US-JX-10: the bell. Notify when the running build finishes, or for every
/// build of this job. The first watch explains what to expect before the
/// OS permission prompt.
class _WatchMenu extends ConsumerWidget {
  const _WatchMenu({required this.job});

  final JenkinsJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watches = ref.watch(buildWatchNotifierProvider);
    final running = job.lastBuild?.building == true ? job.lastBuild : null;
    BuildWatch? find(int? number) => watches
        .where((w) => w.jobUrl == job.url && w.buildNumber == number)
        .firstOrNull;
    final jobWatch = find(null);
    final buildWatch = running == null ? null : find(running.number);
    final active = jobWatch != null || buildWatch != null;

    return PopupMenuButton<VoidCallback>(
      tooltip: 'Notifications',
      icon: Icon(
        active ? Icons.notifications_active : Icons.notifications_none,
      ),
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        if (running != null)
          PopupMenuItem(
            value: buildWatch != null
                ? () => _unwatch(ref, buildWatch)
                : () => _watch(context, ref, build: running),
            child: Text(
              buildWatch != null
                  ? 'Stop notifying for #${running.number}'
                  : 'Notify when #${running.number} finishes',
            ),
          ),
        PopupMenuItem(
          value: jobWatch != null
              ? () => _unwatch(ref, jobWatch)
              : () => _watch(context, ref),
          child: Text(
            jobWatch != null
                ? 'Stop notifying for this job'
                : 'Notify for every build',
          ),
        ),
      ],
    );
  }

  Future<void> _unwatch(WidgetRef ref, BuildWatch watch) =>
      ref.read(buildWatchNotifierProvider.notifier).unwatch(watch);

  Future<void> _watch(
    BuildContext context,
    WidgetRef ref, {
    JenkinsBuild? build,
  }) async {
    final notifier = ref.read(buildWatchNotifierProvider.notifier);
    if (ref.read(buildWatchNotifierProvider).isEmpty) {
      final proceed = await showConfirmationDialog(
        context,
        title: 'Build notifications',
        message:
            "You'll get a notification when the build finishes. While the "
            'app is open that takes up to 30 seconds; while it is closed, '
            'your phone decides when to check (often every 15 minutes or '
            'more). Your phone will ask for permission next.',
        confirmLabel: 'Continue',
      );
      if (!proceed) return;
    }
    final result = build == null
        ? await notifier.watchJob(job)
        : await notifier.watchBuild(job, build);
    if (!context.mounted) return;
    final message = switch (result) {
      WatchResult.added =>
        build == null
            ? "You'll be notified when builds of ${job.label} finish."
            : "You'll be notified when #${build.number} finishes.",
      WatchResult.permissionDenied =>
        'Notifications are off for JobTrigger. Turn them on in your '
            "phone's settings.",
      WatchResult.noServer => 'Choose a Jenkins server first.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
