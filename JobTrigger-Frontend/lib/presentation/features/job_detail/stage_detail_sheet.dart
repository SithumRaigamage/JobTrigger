import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../common_widgets/inline_alert.dart';
import '../../../domain/jenkins/console_log_sanitizer.dart';
import '../../../domain/jenkins/pipeline_stage.dart';
import 'stage_status_style.dart';
import 'stage_steps_notifiers.dart';

/// US-JX-04: a stage's steps and their logs, so a failure is one tap away
/// instead of a scroll through the whole console. A parallel stage lists
/// each branch with its own steps. [onViewFullLog] opens the full console:
/// the fallback when step details aren't available or a step log is
/// truncated.
class StageDetailSheet extends StatelessWidget {
  const StageDetailSheet({
    super.key,
    required this.buildUrl,
    required this.node,
    required this.onViewFullLog,
  });

  final String buildUrl;
  final StageNode node;
  final VoidCallback? onViewFullLog;

  @override
  Widget build(BuildContext context) {
    final stage = node.stage;
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final started = stage.startTimeMillis;
    final duration = stage.durationMillis;
    final running = node.status.toUpperCase() == 'IN_PROGRESS';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Semantics(
                    header: true,
                    child: Text(stage.name, style: textTheme.headlineSmall),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
                style: IconButton.styleFrom(backgroundColor: t.raised),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Status',
                  value: labelForStageStatus(node.status),
                  color: t
                      .status(AppColors.toneForStageStatus(node.status))
                      .foreground,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  label: 'Started',
                  value: started == null
                      ? '—'
                      : clockTime(
                          DateTime.fromMillisecondsSinceEpoch(started),
                          seconds: true,
                        ),
                  mono: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  label: running ? 'Elapsed' : 'Duration',
                  value: duration == null || duration <= 0
                      ? '—'
                      : formatBuildDuration(duration),
                  mono: true,
                ),
              ),
            ],
          ),
          if (stage.errorMessage case final message?) ...[
            const SizedBox(height: 12),
            InlineAlert(message: message),
          ],
          const SizedBox(height: 12),
          if (node.branches.isEmpty)
            _StepList(
              buildUrl: buildUrl,
              stage: stage,
              onViewFullLog: onViewFullLog,
            )
          else
            for (final branch in node.branches) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.call_split_rounded,
                      size: 16,
                      color: t.textMuted,
                    ),
                    const SizedBox(width: 6),
                    _StatusIcon(status: branch.status, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(branch.name, style: textTheme.titleSmall),
                    ),
                  ],
                ),
              ),
              if (branch.errorMessage case final message?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InlineAlert(message: message),
                ),
              _StepList(
                buildUrl: buildUrl,
                stage: branch,
                onViewFullLog: onViewFullLog,
              ),
            ],
          if (onViewFullLog != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: onViewFullLog,
              icon: const Icon(Icons.terminal_rounded),
              label: const Text('View full log'),
            ),
          ],
        ],
      ),
    );
  }
}

/// One of the three figures under the stage name.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.color,
    this.mono = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final valueStyle = textTheme.titleSmall?.copyWith(
      fontSize: 14,
      color: color ?? t.text,
    );
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.labelSmall?.copyWith(fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mono ? AppTypography.mono(valueStyle) : valueStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepList extends ConsumerWidget {
  const _StepList({
    required this.buildUrl,
    required this.stage,
    required this.onViewFullLog,
  });

  final String buildUrl;
  final PipelineStage stage;
  final VoidCallback? onViewFullLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = stage.status.toUpperCase() == 'IN_PROGRESS';
    final steps = ref.watch(
      stageStepsProvider(buildUrl, stage.id, live: running),
    );
    return steps.when(
      skipLoadingOnRefresh: true,
      data: (steps) {
        if (steps == null) {
          return const _Note("Step details aren't available on this server.");
        }
        if (steps.isEmpty) return const _Note('No steps.');
        final firstFailed = steps.indexWhere((step) => step.isFailed);
        return Column(
          children: [
            for (final (index, step) in steps.indexed)
              _StepTile(
                buildUrl: buildUrl,
                step: step,
                // The first failure opens itself: that's why you're here.
                initiallyExpanded: index == firstFailed,
                onViewFullLog: onViewFullLog,
              ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, _) => _Note(describeError(error)),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.buildUrl,
    required this.step,
    required this.initiallyExpanded,
    required this.onViewFullLog,
  });

  final String buildUrl;
  final PipelineStep step;
  final bool initiallyExpanded;
  final VoidCallback? onViewFullLog;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      tilePadding: EdgeInsets.zero,
      leading: _StatusIcon(status: step.status, size: 18),
      title: Text(
        step.name,
        style: AppTypography.mono(Theme.of(context).textTheme.bodyMedium),
      ),
      subtitle: step.description == null
          ? null
          : Text(
              step.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      children: [
        _StepLogView(
          buildUrl: buildUrl,
          step: step,
          onViewFullLog: onViewFullLog,
        ),
      ],
    );
  }
}

class _StepLogView extends ConsumerWidget {
  const _StepLogView({
    required this.buildUrl,
    required this.step,
    required this.onViewFullLog,
  });

  final String buildUrl;
  final PipelineStep step;
  final VoidCallback? onViewFullLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(
      stepLogProvider(buildUrl, step.id, live: step.isRunning),
    );
    return log.when(
      skipLoadingOnRefresh: true,
      data: (log) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTokens.of(context).console,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                log.text.isEmpty
                    ? '(no output)'
                    : sanitizeConsoleLog(log.text).trimRight(),
                style: AppTypography.buildLog.copyWith(
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ),
          if (log.hasMore && onViewFullLog != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewFullLog,
                child: const Text('Truncated — view full log'),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (error, _) => _Note(describeError(error)),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.size});

  final String status;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(
    iconForStageStatus(status),
    size: size,
    color: colorForStageStatus(context, status),
    semanticLabel: labelForStageStatus(status),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}
