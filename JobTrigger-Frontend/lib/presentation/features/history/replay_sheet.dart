import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/cache/server_safety_store.dart';
import '../../../data/credentials/active_server_notifier.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/safety/server_safety.dart';
import '../../../domain/jenkins/parameter_definition.dart';
import '../../../domain/jenkins/parameter_values.dart';
import '../../../domain/jenkins/reconcile_replay_parameters.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/read_only_notice.dart';
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

  /// PI-02/IMP-24: read at tap time — the protection flag can change while
  /// the sheet is open.
  String? get _requiredPhrase =>
      ref.read(serverSafetyNotifierProvider).isProtected(
            SafetyTool.jenkins,
            widget.job.url,
          )
          ? widget.job.label
          : null;

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
    // PI-01/02: replay is a trigger — block it on a read-only server and
    // require the typed job name when this job is protected.
    final safety = ref.watch(serverSafetyNotifierProvider);
    final activeServer = ref.watch(activeServerNotifierProvider);
    final readOnly = activeServer != null &&
        safety.isReadOnly(SafetyTool.jenkins, activeServer.id);

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
              if (readOnly) ...[
                const SizedBox(height: 16),
                const ReadOnlyNotice(toolLabel: 'server'),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isTriggering || readOnly ? null : _replay,
                icon: const Icon(Icons.replay),
                label: Text(
                  readOnly
                      ? 'Read-only'
                      : isTriggering
                      ? 'Replaying…'
                      : 'Replay',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _replay() async {
    final phrase = _requiredPhrase;
    if (phrase != null) {
      final confirmed = await showConfirmationDialog(
        context,
        title: 'Replay ${widget.job.label}?',
        message: 'This starts a new build with the parameters above.',
        confirmLabel: 'Replay',
        requiredPhrase: phrase,
      );
      if (!confirmed || !mounted) return;
    }
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
