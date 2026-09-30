/// Build sections shared by the job detail screen (for the last build) and
/// the build detail screen (for any build, US-JX-14): upstream link, stage
/// chips, test summary and failures, artifacts, and SCM changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/jenkins/build_artifact.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/pipeline_stage.dart';
import '../../../domain/jenkins/scm_change.dart';
import '../../../domain/jenkins/test_report.dart';
import '../../../domain/jenkins/upstream_cause.dart';
import '../../navigation/app_routes.dart';
import 'artifact_download_notifier.dart';
import 'stage_detail_sheet.dart';
import 'stage_status_style.dart';

/// US-PIPE-09: the upstream job/build that caused this one, when known —
/// tappable through to that job's detail (reuses `US-JOB-01`'s existing
/// `NotFoundFailure` handling if it's since been deleted/renamed, no new
/// error handling needed).
class UpstreamLink extends StatelessWidget {
  const UpstreamLink({super.key, required this.cause});

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
class StageChipRow extends StatelessWidget {
  const StageChipRow({
    super.key,
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
class TestReportChip extends StatelessWidget {
  const TestReportChip({super.key, required this.report});

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
class ArtifactsList extends StatelessWidget {
  const ArtifactsList({
    super.key,
    required this.buildUrl,
    required this.artifacts,
  });

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
        .watch(
          artifactDownloadNotifierProvider(buildUrl, artifact.relativePath),
        )
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
                      buildUrl,
                      artifact.relativePath,
                    ).notifier,
                  )
                  .download(artifact),
            ),
        ],
      ),
    );
  }
}

/// US-PIPE-03: collapsed to the first 3 changes past that count, so a
/// large commit batch doesn't push the trigger button off-screen.
class ChangesList extends StatefulWidget {
  const ChangesList({super.key, required this.changes});

  final List<ScmChange> changes;

  @override
  State<ChangesList> createState() => _ChangesListState();
}

class _ChangesListState extends State<ChangesList> {
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
