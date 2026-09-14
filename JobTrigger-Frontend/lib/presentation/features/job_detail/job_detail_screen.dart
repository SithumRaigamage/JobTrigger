import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/jenkins/build_artifact.dart';
import '../../../domain/jenkins/build_progress.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/parameter_definition.dart';
import '../../../domain/jenkins/queue_item.dart';
import '../../../domain/jenkins/scm_change.dart';
import '../../../domain/jenkins/test_report.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import 'artifact_download_notifier.dart';
import 'build_status_polling_notifier.dart';
import 'cancel_build_notifier.dart';
import 'job_detail_notifier.dart';
import 'parameter_form.dart';
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
      body: ResponsiveCenter(
        child: jobAsync.when(
          data: (job) => _JobDetailBody(
            job: job,
            queueItem: queueItem,
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

class _JobDetailBody extends ConsumerWidget {
  const _JobDetailBody({
    required this.job,
    required this.queueItem,
    required this.isTriggering,
    required this.isCancelling,
    required this.onParametersChanged,
    required this.onTrigger,
    required this.onCancel,
    required this.onViewLog,
  });

  final JenkinsJob job;
  final QueueItem? queueItem;
  final bool isTriggering;
  final bool isCancelling;
  final ValueChanged<Map<String, String>> onParametersChanged;
  final VoidCallback onTrigger;
  final VoidCallback? onCancel;
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

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
        16,
        16,
      ),
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
        if (queueItem != null) ...[
          _QueuedCard(queueItem: queueItem!),
          const SizedBox(height: 16),
        ],
        _LastBuildCard(job: job, testReport: testReport, onViewLog: onViewLog),
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
    required this.onViewLog,
  });

  final JenkinsJob job;
  final TestReport? testReport;
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
              if (lastBuild.changes.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ChangesList(changes: lastBuild.changes),
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
                LinearProgressIndicator(
                  value: BuildProgress.ratioFor(lastBuild),
                ),
              ],
            ],
          ],
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
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            Text('Failing tests', style: Theme.of(context).textTheme.titleMedium),
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
