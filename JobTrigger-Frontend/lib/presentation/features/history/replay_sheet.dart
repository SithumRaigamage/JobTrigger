import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/parameter_definition.dart';
import '../../../domain/jenkins/parameter_values.dart';
import '../../../domain/jenkins/reconcile_replay_parameters.dart';
import '../job_detail/parameter_edits_notifier.dart';
import '../job_detail/parameter_files_notifier.dart';
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
  String get _formKey => 'replay:${widget.build.url}';

  List<ParameterDefinition> get _reconciled => reconcileReplayParameters(
    widget.job.parameterDefinitions,
    widget.build.parameterValues,
  );

  @override
  Widget build(BuildContext context) {
    final reconciled = _reconciled;
    final values = effectiveParameterValues(
      reconciled,
      ref.watch(parameterEditsNotifierProvider(_formKey)),
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
                  values: values,
                  onChanged: ref
                      .read(parameterEditsNotifierProvider(_formKey).notifier)
                      .setValue,
                  // Jenkins can't return a past build's uploaded file, so a
                  // file parameter is re-chosen (or left out) on replay.
                  files: ref.watch(parameterFilesNotifierProvider(_formKey)),
                  onPickFile: (name) => pickParameterFile(ref, _formKey, name),
                  onRemoveFile: ref
                      .read(parameterFilesNotifierProvider(_formKey).notifier)
                      .remove,
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
        .trigger(
          job: widget.job,
          parameters: effectiveParameterValues(
            _reconciled,
            ref.read(parameterEditsNotifierProvider(_formKey)),
          ),
          files: ref.read(parameterFilesNotifierProvider(_formKey)),
        );
    if (mounted) navigator.pop();
  }
}
