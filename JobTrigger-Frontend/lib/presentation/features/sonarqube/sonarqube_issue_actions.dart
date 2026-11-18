import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/error_message.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/cache/server_safety_store.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../../domain/safety/server_safety.dart';
import '../../../domain/sonarqube/sonarqube_issue.dart';
import '../../../domain/sonarqube/sonarqube_issue_actions.dart';
import '../../../domain/sonarqube/sonarqube_repository.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/read_only_notice.dart';
import '../../common_widgets/section_label.dart';
import 'sonarqube_change_dialogs.dart';

part 'sonarqube_issue_actions.g.dart';

/// The server's own view of one issue (`US-SQ-WRITE-01..03`): current status
/// and assignee, the transitions it offers, the comments. It is the only
/// source for what the page shows about those, so a change appears once the
/// server has accepted it and this has been read again.
@riverpod
Future<SonarQubeIssueDetail> sonarQubeIssueDetail(
  Ref ref,
  String issueKey,
) async {
  final result = await ref
      .watch(sonarQubeRepositoryProvider)
      .fetchIssueDetail(issueKey);
  return result.fold<SonarQubeIssueDetail>(
    (detail) => detail,
    (Object failure) => throw failure,
  );
}

/// Assign, change status and comment on one issue (batch 7). Each asks for
/// confirmation, sends one request, and only on success re-reads the issue;
/// a refusal is shown as the failure's own message and changes nothing.
class SonarQubeIssueManageCard extends ConsumerStatefulWidget {
  const SonarQubeIssueManageCard({required this.issue, super.key});

  final SonarQubeIssue issue;

  @override
  ConsumerState<SonarQubeIssueManageCard> createState() => _ManageState();
}

class _ManageState extends ConsumerState<SonarQubeIssueManageCard> {
  bool _busy = false;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  SonarQubeRepository get _repo => ref.read(sonarQubeRepositoryProvider);

  /// PI-01/IMP-25: write actions are blocked while the active SonarQube
  /// credential is read-only on this device.
  bool get _readOnly {
    final safety = ref.read(serverSafetyNotifierProvider);
    final active = ref.read(activeSonarQubeCredentialNotifierProvider);
    return active != null && safety.isReadOnly(SafetyTool.sonarqube, active.id);
  }

  /// Runs [change] once the user has confirmed, then refreshes from the
  /// server. Returns whether it was applied.
  Future<bool> _apply(
    Future<Result<void, AppFailure>> Function() change,
    String done,
  ) async {
    if (_readOnly) return false;
    setState(() => _busy = true);
    final result = await change();
    if (!mounted) return false;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Ok():
        ref.invalidate(sonarQubeIssueDetailProvider(widget.issue.key));
        // Wait for the re-read so the screen shows the server's answer.
        await ref
            .read(sonarQubeIssueDetailProvider(widget.issue.key).future)
            .then<void>((_) {}, onError: (Object _) {});
        if (mounted) messenger.showSnackBar(SnackBar(content: Text(done)));
      case Err(:final error):
        messenger.showSnackBar(SnackBar(content: Text(describeError(error))));
    }
    if (mounted) setState(() => _busy = false);
    return result is Ok;
  }

  Future<void> _changeStatus(SonarQubeIssueDetail detail) async {
    final transition = await pickSonarQubeChoice<String>(
      context,
      title: 'Change status',
      // Only what the server offers for this issue and this user.
      choices: [
        for (final t in detail.transitions) (sonarQubeTransitionLabel(t), t),
      ],
    );
    if (transition == null || !mounted) return;
    final label = sonarQubeTransitionLabel(transition);
    final yes = await confirmSonarQubeChange(
      context,
      title: '$label?',
      body: 'This changes the issue on SonarQube for everyone.',
      confirmLabel: label,
    );
    if (!yes) return;
    await _apply(
      () => _repo.transitionIssue(widget.issue.key, transition),
      'Status changed',
    );
  }

  Future<void> _assign(SonarQubeIssueDetail detail) async {
    final choice = await pickSonarQubeChoice<String>(
      context,
      title: 'Assign to',
      choices: [
        ('Me', sonarQubeAssignToMe),
        ('Someone else…', 'other'),
        if (detail.assignee != null) ('Unassign', ''),
      ],
    );
    if (choice == null || !mounted) return;
    var assignee = choice;
    if (choice == 'other') {
      final login = await askSonarQubeText(
        context,
        title: 'Assign to',
        label: 'SonarQube login',
        confirmLabel: 'Next',
      );
      if (login == null || !mounted) return;
      assignee = login;
    }
    final who = assignee.isEmpty
        ? 'Unassign this issue'
        : (assignee == sonarQubeAssignToMe
              ? 'Assign this issue to you'
              : 'Assign this issue to $assignee');
    final yes = await confirmSonarQubeChange(
      context,
      title: '$who?',
      body: 'This changes the issue on SonarQube for everyone.',
      confirmLabel: assignee.isEmpty ? 'Unassign' : 'Assign',
    );
    if (!yes) return;
    await _apply(
      () => _repo.assignIssue(widget.issue.key, assignee),
      assignee.isEmpty ? 'Unassigned' : 'Assigned',
    );
  }

  Future<void> _postComment() async {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    final yes = await confirmSonarQubeChange(
      context,
      title: 'Post this comment?',
      body:
          'Comments are visible to everyone who can see this project on '
          'SonarQube.',
      confirmLabel: 'Post',
    );
    if (!yes) return;
    final posted = await _apply(
      () => _repo.addIssueComment(widget.issue.key, text),
      'Comment posted',
    );
    // Cleared only once the server has taken it, so a refusal keeps the text.
    if (posted) _comment.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final detailAsync = ref.watch(
      sonarQubeIssueDetailProvider(widget.issue.key),
    );
    final safety = ref.watch(serverSafetyNotifierProvider);
    final activeCredential = ref.watch(
      activeSonarQubeCredentialNotifierProvider,
    );
    final readOnly =
        activeCredential != null &&
        safety.isReadOnly(SafetyTool.sonarqube, activeCredential.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Manage'),
        const SizedBox(height: 8),
        GlassSurface.card(
          padding: const EdgeInsets.all(16),
          child: detailAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(
              describeError(error),
              style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
            ),
            data: (detail) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (readOnly) ...[
                  const ReadOnlyNotice(toolLabel: 'SonarQube account'),
                  const SizedBox(height: 12),
                ],
                _Line(
                  label: 'Status',
                  value: sonarQubeIssueStatusLabel(detail.status),
                  action: 'Change',
                  onPressed: _busy || readOnly || detail.transitions.isEmpty
                      ? null
                      : () => _changeStatus(detail),
                ),
                _Line(
                  label: 'Assignee',
                  value: detail.assignee ?? 'Unassigned',
                  action: 'Assign',
                  onPressed: _busy || readOnly ? null : () => _assign(detail),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _comment,
                  minLines: 2,
                  maxLines: 5,
                  enabled: !_busy && !readOnly,
                  decoration: const InputDecoration(
                    labelText: 'Add a comment',
                    helperText: 'Visible to everyone on this project.',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _busy || readOnly ? null : _postComment,
                    child: Text(_busy ? 'Working…' : 'Post comment'),
                  ),
                ),
                if (detail.comments.isNotEmpty) ...[
                  const Divider(height: 24),
                  for (final c in detail.comments)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              c.login ?? 'Someone',
                              if (c.createdAt != null)
                                relativeTime(c.createdAt!),
                            ].join(' · '),
                            style: textTheme.bodySmall?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                          Text(c.text, style: textTheme.bodyMedium),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// `OPEN` → "Open", `FALSE_POSITIVE` → "False positive".
String sonarQubeIssueStatusLabel(String status) {
  final words = status.replaceAll('_', ' ').toLowerCase();
  return words.isEmpty ? status : words[0].toUpperCase() + words.substring(1);
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    required this.action,
    required this.onPressed,
  });

  final String label;
  final String value;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
        ),
        Expanded(child: Text(value)),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}
