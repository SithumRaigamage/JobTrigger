import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/github/github_job.dart';
import '../../../domain/github/github_repo.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../build_log/console_log_viewer.dart';
import '../build_log/console_notifiers.dart';
import 'github_job_log_notifier.dart';
import 'github_jobs_notifier.dart';

/// A job's log (`US-GH-LOG-01`), shown in the same virtualized console
/// viewer as Jenkins build logs. GitHub can't tail a running job's log, so
/// until the job completes there is only a "check now" action, never
/// automatic polling. Copy and share (`US-GH-LOG-02`) always use the whole
/// downloaded text.
class GitHubJobLogScreen extends ConsumerWidget {
  const GitHubJobLogScreen({
    required this.repo,
    required this.runId,
    required this.job,
    super.key,
  });

  final GitHubRepo repo;
  final int runId;
  final GitHubJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The job's status is live: the run screen under this one keeps its
    // 5s poll running, so a finishing job flips this screen to its log.
    final jobs = ref.watch(
      gitHubJobsNotifierProvider(repo.owner, repo.name, runId),
    );
    final current = jobs.value?.where((j) => j.id == job.id).firstOrNull ?? job;

    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final logAsync = current.isCompleted
        ? ref.watch(gitHubJobLogNotifierProvider(repo.owner, repo.name, job.id))
        : null;
    final log = logAsync?.value;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      tooltip: 'Back',
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            current.name,
                            style: textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            repo.fullName,
                            style: textTheme.bodySmall?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      tooltip: 'Copy log',
                      onPressed: log == null
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: log.text),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Log copied to clipboard'),
                                  ),
                                );
                              }
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.ios_share_rounded, size: 20),
                      tooltip: 'Share log',
                      onPressed: log == null
                          ? null
                          : () => SharePlus.instance.share(
                              ShareParams(
                                text: log.text,
                                subject: '${current.name} log',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(context, ref, current, logAsync)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    GitHubJob current,
    AsyncValue<GitHubJobLog>? logAsync,
  ) {
    final t = AppTokens.of(context);
    if (logAsync == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty_rounded, size: 40, color: t.textMuted),
              const SizedBox(height: 12),
              Text(
                'The log is available once this job finishes.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref
                    .read(
                      gitHubJobsNotifierProvider(
                        repo.owner,
                        repo.name,
                        runId,
                      ).notifier,
                    )
                    .refresh(),
                child: const Text('Check now'),
              ),
            ],
          ),
        ),
      );
    }
    return logAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ConnectionErrorView(
          message: describeError(error),
          onRetry: () => ref
              .read(
                gitHubJobLogNotifierProvider(
                  repo.owner,
                  repo.name,
                  job.id,
                ).notifier,
              )
              .refresh(),
        ),
      ),
      data: (log) => ConsoleLogViewer(
        lines: log.lines,
        prefs: ref.watch(consolePrefsNotifierProvider),
      ),
    );
  }
}
