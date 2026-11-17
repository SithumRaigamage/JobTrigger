import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/github_repository_impl.dart';
import '../../../domain/jenkins/console_decoder.dart';

part 'github_job_log_notifier.g.dart';

/// A job's finished log: the raw [text] for copy and share (never partial,
/// `US-GH-LOG-02`) and its decoded [lines] for the shared console viewer.
class GitHubJobLog {
  const GitHubJobLog({required this.text, required this.lines});

  final String text;
  final List<ConsoleLine> lines;
}

/// One-shot fetch of a completed job's log (`US-GH-LOG-01`), keyed by
/// `(owner, repo, jobId)`. There is no polling: a refresh is the user's
/// explicit "check again", since GitHub offers no safe way to tail a log.
@riverpod
class GitHubJobLogNotifier extends _$GitHubJobLogNotifier {
  @override
  Future<GitHubJobLog> build(String owner, String repo, int jobId) async {
    final result = await ref
        .watch(gitHubRepositoryProvider)
        .fetchJobLog(owner, repo, jobId);
    final text = result.fold((text) => text, (failure) => throw failure);
    // A trailing newline completes the last line, so it isn't left pending.
    final decoder = ConsoleDecoder();
    final lines = decoder.addChunk(text.endsWith('\n') ? text : '$text\n');
    return GitHubJobLog(text: text, lines: lines);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
