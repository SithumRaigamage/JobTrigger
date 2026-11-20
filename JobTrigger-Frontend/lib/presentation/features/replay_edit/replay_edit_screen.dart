import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/cache/server_safety_store.dart';
import '../../../data/credentials/active_server_notifier.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/replay_script.dart';
import '../../../domain/safety/server_safety.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/read_only_notice.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/tool_server_credential_header.dart';
import '../../navigation/app_routes.dart';
import 'replay_edit_notifier.dart';

/// US-JX-16: replay a pipeline build with an edited script. The script comes
/// from the job's `config.xml` (inline pipelines only, AC2/AC3); submitting
/// asks twice (AC6) and then opens the new build (AC8). See
/// `docs/user-stories/jenkins/16-jenkins-extended.md`.
class ReplayEditScreen extends ConsumerStatefulWidget {
  const ReplayEditScreen({super.key, required this.job, required this.build});

  final JenkinsJob job;
  final JenkinsBuild build;

  @override
  ConsumerState<ReplayEditScreen> createState() => _ReplayEditScreenState();
}

class _ReplayEditScreenState extends ConsumerState<ReplayEditScreen> {
  final _editor = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scriptAsync = ref.watch(replayScriptProvider(widget.job.url));
    final submitting = ref
        .watch(replayEditNotifierProvider(widget.build.url))
        .isLoading;
    final server = ref.watch(activeServerNotifierProvider);
    final safety = ref.watch(serverSafetyNotifierProvider);
    final readOnly =
        server != null && safety.isReadOnly(SafetyTool.jenkins, server.id);
    final textTheme = Theme.of(context).textTheme;

    // Fill the editor once, when the script first arrives; later rebuilds
    // keep the user's edits.
    if (scriptAsync.value case InlineReplayScript(
      :final script,
    ) when !_loaded) {
      _editor.text = script;
      _loaded = true;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (server != null)
              JenkinsServerHeader(
                server: server,
                onSwitch: (chosen) {
                  ref
                      .read(activeServerNotifierProvider.notifier)
                      .setActiveServer(chosen);
                  // Keyed by the old server's URLs (AUD-45): go Home.
                  context.go(AppRoutes.home);
                },
              ),
            ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Replay #${widget.build.number} with edits',
                          style: textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (scriptAsync.value case InlineReplayScript(
                      :final sandbox,
                    ))
                      Chip(
                        label: Text(sandbox ? 'Sandbox' : 'No sandbox'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                // Always dark, like the console (UI notes).
                color: AppColors.consoleDark,
                child: scriptAsync.when(
                  data: (script) => switch (script) {
                    InlineReplayScript() => _editorView(context),
                    ScmReplayScript() => const _Message(
                      icon: Icons.source_outlined,
                      text:
                          'Replay with edits works for jobs whose script is '
                          "in Jenkins. This job's Jenkinsfile comes from a "
                          'repository.',
                    ),
                    NoReplayScript() => const _Message(
                      icon: Icons.code_off_rounded,
                      text: 'This job has no pipeline script to edit.',
                    ),
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => switch (error) {
                    DemoUnavailableFailure() => const _Message(
                      icon: Icons.science_outlined,
                      text: "Replay with edits isn't available in the demo.",
                    ),
                    PermissionFailure() => const _Message(
                      icon: Icons.lock_outline_rounded,
                      text:
                          "You need permission to read this job's "
                          'configuration to load its script.',
                    ),
                    _ => Center(
                      child: ConnectionErrorView(
                        message: describeError(error),
                        onRetry: () => ref.invalidate(
                          replayScriptProvider(widget.job.url),
                        ),
                      ),
                    ),
                  },
                ),
              ),
            ),
            if (scriptAsync.value is InlineReplayScript)
              ResponsiveCenter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (readOnly) ...[
                        const ReadOnlyNotice(toolLabel: 'server'),
                        const SizedBox(height: 10),
                      ],
                      FilledButton.icon(
                        onPressed: readOnly || submitting
                            ? null
                            : () => _replay(server?.serverName ?? 'Jenkins'),
                        icon: const Icon(Icons.replay),
                        label: Text(
                          readOnly
                              ? 'Read-only'
                              : submitting
                              ? 'Replaying…'
                              : 'Replay',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _editorView(BuildContext context) {
    final mono = AppTypography.mono(
      Theme.of(context).textTheme.bodySmall,
    ).copyWith(color: AppColors.consoleText, fontSize: 13, height: 1.45);
    return Column(
      children: [
        // AC4: the job's current script, not necessarily what ran.
        if (wasReplayed(widget.build.causes))
          const _Banner(
            text:
                'This build was itself a replay. The script below is the '
                "job's current script, which may differ from what it ran.",
          ),
        Expanded(
          child: Semantics(
            label: 'Pipeline script',
            textField: true,
            child: TextField(
              key: const ValueKey('replay-script-editor'),
              controller: _editor,
              maxLines: null,
              expands: true,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              style: mono,
              cursorColor: AppColors.consoleText,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
        ),
      ],
    );
  }

  /// AC6: two confirmations, the second naming the server and requiring the
  /// job name; then AC8.
  Future<void> _replay(String serverName) async {
    final number = widget.build.number;
    final first = await showConfirmationDialog(
      context,
      title: 'Replay #$number with edits?',
      message:
          'A new build of ${widget.job.label} starts with the script above. '
          'The job itself is not changed.',
      confirmLabel: 'Continue',
    );
    if (!first || !mounted) return;
    final second = await showConfirmationDialog(
      context,
      title: 'Run edited pipeline code?',
      message: 'This runs arbitrary pipeline code on $serverName.',
      confirmLabel: 'Replay',
      destructive: true,
      requiredPhrase: widget.job.label,
    );
    if (!second || !mounted) return;
    final router = GoRouter.of(context);
    final outcome = await ref
        .read(replayEditNotifierProvider(widget.build.url).notifier)
        .submit(job: widget.job, build: widget.build, script: _editor.text);
    if (!mounted) return;
    switch (outcome) {
      case ReplayedBuild(:final build):
        unawaited(router.pushReplacement(AppRoutes.buildDetail, extra: build));
      case ReplayStarted():
        unawaited(
          router.pushReplacement(AppRoutes.jobHistory, extra: widget.job),
        );
      case ReplayRefused() || null:
        break;
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.consoleText),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.consoleText),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.consoleBar,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.consoleText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.consoleText,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
