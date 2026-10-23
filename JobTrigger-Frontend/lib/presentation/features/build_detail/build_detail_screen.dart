import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/jenkins/history_filter.dart';
import '../../common_widgets/grouped_card.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/section_label.dart';
import '../../common_widgets/status_pill.dart';
import '../../../domain/jenkins/html_text.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../job_detail/build_sections.dart';
import '../job_detail/pipeline_stages_notifier.dart';
import '../job_detail/test_report_notifier.dart';
import 'build_detail_notifier.dart';

/// US-JX-14: any build in full (result, causes, parameters, changes,
/// stages, tests, artifacts), plus "keep forever" and an editable
/// description. Reached from history and the last success/failure links.
/// [jenkinsBuild] is the (possibly partial) build it was opened from, shown
/// until the full fetch lands. Laid out to the P14 design
/// (`UI-UX/screens/14-build-detail`).
class BuildDetailScreen extends ConsumerWidget {
  const BuildDetailScreen({super.key, required this.jenkinsBuild});

  final JenkinsBuild jenkinsBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = jenkinsBuild.url;
    final detail = ref.watch(buildDetailNotifierProvider(url));
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
                child: detail.when(
                  skipLoadingOnRefresh: true,
                  data: (build) => _BuildBody(jenkinsBuild: build),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () =>
                          ref.invalidate(buildDetailNotifierProvider(url)),
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

class _BuildBody extends ConsumerWidget {
  const _BuildBody({required this.jenkinsBuild});

  final JenkinsBuild jenkinsBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final build = jenkinsBuild;
    final stages = ref.watch(pipelineStagesNotifierProvider(build.url)).value;
    final report = ref.watch(testReportNotifierProvider(build.url)).value;
    void viewLog() => context.push(AppRoutes.buildLog, extra: build);

    final jobLabel = jobLabelFromBuildUrl(build.url);
    final number = '#${build.number}';
    final name = build.displayName;
    final started = fromJenkinsTimestamp(build.timestamp);
    final duration = build.duration;
    final failedStage = stages
        ?.where((stage) => stage.status.toUpperCase() == 'FAILED')
        .firstOrNull;
    final broken =
        !build.building &&
        (build.result == 'FAILURE' || build.result == 'UNSTABLE');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        if (jobLabel.isNotEmpty)
          Text(
            jobLabel,
            style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Flexible(
              child: Semantics(
                header: true,
                child: Text(
                  number,
                  style: AppTypography.mono(textTheme.headlineMedium),
                ),
              ),
            ),
            const SizedBox(width: 12),
            StatusPill.forBuildResult(build.building ? null : build.result),
          ],
        ),
        // A custom build name ("Release 1.4"), when it isn't just "#n".
        if (name != null && name.isNotEmpty && name != number) ...[
          const SizedBox(height: 4),
          Text(name, style: textTheme.titleSmall),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Figure(
                label: build.building ? 'Running for' : 'Duration',
                value: build.building
                    ? formatBuildDuration(
                        DateTime.now().millisecondsSinceEpoch - build.timestamp,
                      )
                    : duration == null
                    ? '—'
                    : formatBuildDuration(duration),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Figure(
                label: 'Started',
                value: '${dayLabel(started)} ${clockTime(started)}',
              ),
            ),
          ],
        ),
        if (build.causes.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Figure(
            label: 'Triggered by',
            value: build.causes.join(', '),
            mono: false,
          ),
        ],
        if (build.upstreamCause case final cause?) ...[
          const SizedBox(height: 8),
          UpstreamLink(cause: cause),
        ],
        if (broken) ...[
          const SizedBox(height: 14),
          InlineAlert(
            tone: build.result == 'UNSTABLE'
                ? StatusTone.unstable
                : StatusTone.failure,
            title: failedStage == null
                ? (build.result == 'UNSTABLE' ? 'Unstable' : 'Build failed')
                : 'Failed at stage “${failedStage.name}”',
            message: report != null && report.failCount > 0
                ? '${report.failCount} test'
                      '${report.failCount == 1 ? '' : 's'} failed'
                : 'See the console log for the error.',
          ),
        ],
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: viewLog,
          icon: const Icon(Icons.terminal_rounded),
          label: const Text('Console log'),
        ),
        if (stages != null && stages.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionLabel('Pipeline'),
          const SizedBox(height: 8),
          StageChipRow(buildUrl: build.url, stages: stages, onViewLog: viewLog),
        ],
        if (report != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TestReportChip(report: report),
          ),
        ],
        if (build.artifacts.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionLabel('Artifacts'),
          const SizedBox(height: 4),
          ArtifactsList(buildUrl: build.url, artifacts: build.artifacts),
        ],
        if (build.parameterValues.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionLabel('Parameters'),
          const SizedBox(height: 8),
          GroupedCard(
            children: [
              for (final MapEntry(:key, :value)
                  in build.parameterValues.entries)
                _ParameterRow(name: key, value: value),
            ],
          ),
        ],
        if (build.changes.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionLabel('Changes'),
          ChangesList(changes: build.changes),
        ],
        const SizedBox(height: 20),
        _DescriptionCard(jenkinsBuild: build),
        const SizedBox(height: 12),
        _KeepForeverTile(jenkinsBuild: build),
      ],
    );
  }
}

/// A labelled figure: duration, start, cause.
class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.mono = true});

  final String label;
  final String value;

  /// Times and durations are monospaced; a sentence like the cause isn't.
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.labelSmall?.copyWith(fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              value,
              style: mono
                  ? AppTypography.mono(
                      textTheme.bodyMedium,
                    ).copyWith(fontSize: 14)
                  : textTheme.bodyMedium?.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// One parameter the build ran with, as Jenkins spells it.
class _ParameterRow extends StatelessWidget {
  const _ParameterRow({required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.mono(Theme.of(context).textTheme.bodySmall);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: style),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: style.copyWith(color: AppTokens.of(context).text),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Keep this build forever": exempt from log rotation. Asks first either
/// way, since un-keeping lets Jenkins delete it on its next rotation.
class _KeepForeverTile extends ConsumerWidget {
  const _KeepForeverTile({required this.jenkinsBuild});

  final JenkinsBuild jenkinsBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kept = jenkinsBuild.keepLog ?? false;
    return GroupedCard(
      children: [
        SwitchListTile(
          secondary: Icon(kept ? Icons.lock_rounded : Icons.lock_open_rounded),
          title: const Text('Keep this build forever'),
          subtitle: Text(
            kept
                ? 'Exempt from log rotation'
                : 'Jenkins may delete it when rotating old builds',
          ),
          value: kept,
          onChanged: (_) async {
            final confirmed = await showConfirmationDialog(
              context,
              title: kept ? 'Stop keeping forever?' : 'Keep forever?',
              message: kept
                  ? 'Jenkins may then delete this build when it rotates old '
                        'builds.'
                  : "This build will be kept regardless of the job's "
                        'rotation settings.',
              confirmLabel: kept ? 'Stop keeping' : 'Keep',
              destructive: kept,
            );
            if (!confirmed) return;
            await ref
                .read(buildDetailNotifierProvider(jenkinsBuild.url).notifier)
                .toggleKeepForever();
          },
        ),
      ],
    );
  }
}

/// The build description, always shown as plain text: Jenkins stores it
/// as HTML, which the app never renders.
class _DescriptionCard extends ConsumerWidget {
  const _DescriptionCard({required this.jenkinsBuild});

  final JenkinsBuild jenkinsBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = htmlToPlainText(jenkinsBuild.description ?? '');
    final textTheme = Theme.of(context).textTheme;
    return GlassSurface.card(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionLabel('Description')),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit description',
                onPressed: () => _edit(context, ref, text),
              ),
            ],
          ),
          Text(
            text.isEmpty ? 'No description' : text,
            style: text.isEmpty
                ? textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)
                : textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => _DescriptionDialog(initial: current),
    );
    if (saved == null || saved == current) return;
    await ref
        .read(buildDetailNotifierProvider(jenkinsBuild.url).notifier)
        .setDescription(saved);
  }
}

/// Owns its text controller, so it's disposed only after the dialog's
/// closing animation (which still reads it) has finished — disposing it
/// right after `showDialog` returned crashed (caught by a widget test).
class _DescriptionDialog extends StatefulWidget {
  const _DescriptionDialog({required this.initial});

  final String initial;

  @override
  State<_DescriptionDialog> createState() => _DescriptionDialogState();
}

class _DescriptionDialogState extends State<_DescriptionDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Build description'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: 'e.g. Release 1.4.0 — shipped to production',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
