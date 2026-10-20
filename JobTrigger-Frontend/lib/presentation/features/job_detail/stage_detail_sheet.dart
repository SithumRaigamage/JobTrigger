import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_typography.dart';
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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            children: [
              _StatusIcon(status: node.status, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(stage.name, style: textTheme.titleMedium)),
              Text(node.status, style: textTheme.labelMedium),
            ],
          ),
          if (stage.errorMessage case final message?) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
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
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.call_split, size: 16),
                    const SizedBox(width: 6),
                    _StatusIcon(status: branch.status, size: 16),
                    const SizedBox(width: 6),
                    Text(branch.name, style: textTheme.titleSmall),
                  ],
                ),
              ),
              if (branch.errorMessage case final message?)
                Text(
                  message,
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              _StepList(
                buildUrl: buildUrl,
                stage: branch,
                onViewFullLog: onViewFullLog,
              ),
            ],
          if (onViewFullLog != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onViewFullLog,
              icon: const Icon(Icons.article_outlined),
              label: const Text('View full log'),
            ),
          ],
        ],
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
      title: Text(step.name),
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
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                log.text.isEmpty
                    ? '(no output)'
                    : sanitizeConsoleLog(log.text).trimRight(),
                style: AppTypography.buildLog.copyWith(color: Colors.white),
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
    color: colorForStageStatus(status),
    semanticLabel: status,
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
