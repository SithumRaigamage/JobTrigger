import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/parameter_definition.dart';
import '../../../domain/jenkins/reconcile_replay_parameters.dart';
import '../job_detail/parameter_form.dart';
import '../job_detail/trigger_build_notifier.dart';

/// US-PIPE-08: re-triggers [build]'s job pre-filled with that build's
/// actual recorded parameter values (`reconcileReplayParameters`), not
/// the job's current declared defaults. Reuses `ParameterForm`
/// (`US-JOB-03`) and `TriggerBuildNotifier` unchanged — replay is not a
/// separate Jenkins endpoint, just a pre-filled trigger, so it gets the
/// same `NFR-SEC-06` crumb handling and success/error toast for free.
/// Opening this sheet and reviewing/editing the pre-filled values before
/// tapping "Replay" is this flow's confirmation step, the same posture
/// `US-JOB-02`/`03` already have (no separate confirm dialog on top).
class ReplaySheet extends ConsumerStatefulWidget {
  const ReplaySheet({super.key, required this.job, required this.build});

  final JenkinsJob job;
  final JenkinsBuild build;

  @override
  ConsumerState<ReplaySheet> createState() => _ReplaySheetState();
}

class _ReplaySheetState extends ConsumerState<ReplaySheet> {
  Map<String, String> _parameterValues = const {};

  @override
  Widget build(BuildContext context) {
    final currentDefinitions = widget.job.property
        .expand(
          (prop) => prop.parameterDefinitions ?? const <ParameterDefinition>[],
        )
        .toList();
    final reconciled = reconcileReplayParameters(
      currentDefinitions,
      widget.build.parameterValues,
    );
    final isTriggering = ref
        .watch(triggerBuildNotifierProvider(widget.job.url))
        .isLoading;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Replay #${widget.build.number}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Re-runs this job with the parameters it used before — '
                'review and edit them before confirming.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (reconciled.isNotEmpty) ...[
                const SizedBox(height: 16),
                ParameterForm(
                  parameters: reconciled,
                  onChanged: (values) => _parameterValues = values,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isTriggering ? null : _replay,
                icon: const Icon(Icons.replay),
                label: Text(isTriggering ? 'Replaying…' : 'Replay'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _replay() async {
    final navigator = Navigator.of(context);
    await ref
        .read(triggerBuildNotifierProvider(widget.job.url).notifier)
        .trigger(job: widget.job, parameters: _parameterValues);
    if (mounted) navigator.pop();
  }
}
