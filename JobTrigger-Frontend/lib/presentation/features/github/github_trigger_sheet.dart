import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/github/github_repo.dart';
import '../../../domain/github/github_workflow.dart';
import '../../../domain/github/workflow_inputs.dart';
import 'github_trigger_notifier.dart';

/// The trigger form (`US-GH-RUN-02`): a branch/tag field defaulting to the
/// repo's default branch, plus untyped key/value inputs, then a confirm
/// step before anything is sent.
Future<void> showGitHubTriggerSheet(
  BuildContext context, {
  required GitHubRepo repo,
  required GitHubWorkflow workflow,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => GitHubTriggerSheet(repo: repo, workflow: workflow),
);

class GitHubTriggerSheet extends ConsumerStatefulWidget {
  const GitHubTriggerSheet({
    required this.repo,
    required this.workflow,
    super.key,
  });

  final GitHubRepo repo;
  final GitHubWorkflow workflow;

  @override
  ConsumerState<GitHubTriggerSheet> createState() => _GitHubTriggerSheetState();
}

class _InputRow {
  final name = TextEditingController();
  final value = TextEditingController();

  void dispose() {
    name.dispose();
    value.dispose();
  }
}

class _GitHubTriggerSheetState extends ConsumerState<GitHubTriggerSheet> {
  late final TextEditingController _ref = TextEditingController(
    text: widget.repo.defaultBranch,
  );
  final List<_InputRow> _rows = [];
  String? _error;

  @override
  void dispose() {
    _ref.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final branch = _ref.text.trim();
    if (branch.isEmpty) {
      setState(() => _error = 'Enter a branch or tag to run on.');
      return;
    }
    final cleaned = cleanWorkflowInputs([
      for (final r in _rows) (r.name.text, r.value.text),
    ]);
    if (!cleaned.isValid) {
      setState(() => _error = cleaned.error);
      return;
    }
    setState(() => _error = null);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Run ${widget.workflow.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.repo.fullName} on $branch'),
            if (cleaned.inputs.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Inputs'),
              for (final e in cleaned.inputs.entries)
                Text('${e.key} = ${e.value}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Run workflow'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(
      gitHubTriggerNotifierProvider(
        widget.repo.owner,
        widget.repo.name,
        widget.workflow.id,
      ).notifier,
    );
    Navigator.of(context).pop();
    await notifier.trigger(
      ref: branch,
      inputs: cleaned.inputs,
      workflowName: widget.workflow.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Run workflow', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              widget.workflow.name,
              style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ref,
              decoration: const InputDecoration(
                labelText: 'Branch or tag',
                border: OutlineInputBorder(),
              ),
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: 16),
            Text('Inputs (optional)', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              "GitHub doesn't share a workflow's input names, so enter any it "
              'expects yourself.',
              style: textTheme.bodySmall?.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _rows.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _rows[i].name,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _rows[i].value,
                        decoration: const InputDecoration(
                          labelText: 'Value',
                          border: OutlineInputBorder(),
                        ),
                        autocorrect: false,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove input',
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: () =>
                          setState(() => _rows.removeAt(i).dispose()),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _rows.add(_InputRow())),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add input'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('Run workflow')),
          ],
        ),
      ),
    );
  }
}
