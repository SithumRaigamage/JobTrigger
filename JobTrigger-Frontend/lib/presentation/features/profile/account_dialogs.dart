import 'package:flutter/material.dart';

/// Submits the dialog's input; returns the problem to show inline, or null
/// on success (the dialog then closes and reports true).
typedef AccountAction = Future<String?> Function(List<String> values);

/// AUD-48: "Change password" — current, new, and confirmation. Rules and
/// the request live in `AuthNotifier.changePassword`; this only collects
/// the fields and shows its answer. True when the password was changed.
Future<bool> showChangePasswordDialog(
  BuildContext context, {
  required AccountAction onSubmit,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => _PasswordFormDialog(
        title: 'Change password',
        message:
            'Every other device signed in to this account will be signed '
            'out.',
        labels: const [
          'Current password',
          'New password',
          'Confirm new password',
        ],
        confirmLabel: 'Change password',
        destructive: false,
        onSubmit: onSubmit,
      ),
    ) ??
    false;

/// AUD-48: "Delete account" — permanent, so it asks for the password. True
/// when the account was deleted.
Future<bool> showDeleteAccountDialog(
  BuildContext context, {
  required AccountAction onSubmit,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => _PasswordFormDialog(
        title: 'Delete account?',
        message:
            'Your account and every Jenkins server, GitHub credential, and '
            'SonarQube credential saved with it are deleted permanently. '
            'Your CI servers themselves are not affected.',
        labels: const ['Password'],
        confirmLabel: 'Delete account',
        destructive: true,
        onSubmit: onSubmit,
      ),
    ) ??
    false;

class _PasswordFormDialog extends StatefulWidget {
  const _PasswordFormDialog({
    required this.title,
    required this.message,
    required this.labels,
    required this.confirmLabel,
    required this.destructive,
    required this.onSubmit,
  });

  final String title;
  final String message;
  final List<String> labels;
  final String confirmLabel;
  final bool destructive;
  final AccountAction onSubmit;

  @override
  State<_PasswordFormDialog> createState() => _PasswordFormDialogState();
}

class _PasswordFormDialogState extends State<_PasswordFormDialog> {
  late final _controllers = [
    for (final _ in widget.labels) TextEditingController(),
  ];
  String? _problem;
  bool _busy = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    final problem = await widget.onSubmit([
      for (final controller in _controllers) controller.text,
    ]);
    if (!mounted) return;
    if (problem == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _problem = problem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message),
            for (final (i, label) in widget.labels.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  controller: _controllers[i],
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  enabled: !_busy,
                  autofillHints: [
                    i == 0 ? AutofillHints.password : AutofillHints.newPassword,
                  ],
                  decoration: InputDecoration(labelText: label),
                ),
              ),
            if (_problem case final problem?)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    problem,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: widget.destructive
              ? TextButton.styleFrom(foregroundColor: colorScheme.error)
              : null,
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
