import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
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
/// until the full fetch lands.
class BuildDetailScreen extends ConsumerWidget {
  const BuildDetailScreen({super.key, required this.jenkinsBuild});

  final JenkinsBuild jenkinsBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = jenkinsBuild.url;
    final detail = ref.watch(buildDetailNotifierProvider(url));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(jenkinsBuild.displayName ?? '#${jenkinsBuild.number}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.article_outlined),
            tooltip: 'View log',
            onPressed: () =>
                context.push(AppRoutes.buildLog, extra: jenkinsBuild),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: detail.when(
          skipLoadingOnRefresh: true,
          data: (build) => _BuildBody(jenkinsBuild: build),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: ConnectionErrorView(
              message: describeError(error),
              onRetry: () => ref.invalidate(buildDetailNotifierProvider(url)),
            ),
          ),
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
    final stages = ref
        .watch(pipelineStagesNotifierProvider(jenkinsBuild.url))
        .value;
    final report = ref
        .watch(testReportNotifierProvider(jenkinsBuild.url))
        .value;
    void viewLog() => context.push(AppRoutes.buildLog, extra: jenkinsBuild);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
        16,
        24,
      ),
      children: [
        GlassSurface.card(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    jenkinsBuild.building ? Icons.autorenew : Icons.circle,
                    size: 16,
                    color: AppColors.forBuildResult(jenkinsBuild.result),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    jenkinsBuild.building
                        ? 'Building…'
                        : (jenkinsBuild.result ?? 'Unknown'),
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [
                  'Started ${relativeTime(fromJenkinsTimestamp(jenkinsBuild.timestamp))}',
                  if (!jenkinsBuild.building && jenkinsBuild.duration != null)
                    'took ${formatBuildDuration(jenkinsBuild.duration!)}',
                ].join(' · '),
                style: textTheme.bodySmall,
              ),
              if (jenkinsBuild.causes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  jenkinsBuild.causes.join(', '),
                  style: textTheme.bodySmall,
                ),
              ],
              if (jenkinsBuild.upstreamCause case final cause?) ...[
                const SizedBox(height: 4),
                UpstreamLink(cause: cause),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _KeepForeverTile(jenkinsBuild: jenkinsBuild),
        const SizedBox(height: 12),
        _DescriptionCard(jenkinsBuild: jenkinsBuild),
        if (jenkinsBuild.parameterValues.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Parameters', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          for (final MapEntry(:key, :value)
              in jenkinsBuild.parameterValues.entries)
            Text('$key: $value', style: textTheme.bodySmall),
        ],
        if (jenkinsBuild.changes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Changes', style: textTheme.titleSmall),
          ChangesList(changes: jenkinsBuild.changes),
        ],
        if (stages != null && stages.isNotEmpty) ...[
          const SizedBox(height: 16),
          StageChipRow(
            buildUrl: jenkinsBuild.url,
            stages: stages,
            onViewLog: viewLog,
          ),
        ],
        if (report != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TestReportChip(report: report),
          ),
        ],
        if (jenkinsBuild.artifacts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Artifacts', style: textTheme.titleSmall),
          ArtifactsList(
            buildUrl: jenkinsBuild.url,
            artifacts: jenkinsBuild.artifacts,
          ),
        ],
      ],
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
    return GlassSurface.card(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SwitchListTile(
        secondary: Icon(kept ? Icons.lock : Icons.lock_open),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Description', style: textTheme.titleSmall)),
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
