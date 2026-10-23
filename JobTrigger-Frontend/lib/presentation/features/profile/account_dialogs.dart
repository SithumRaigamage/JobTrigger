import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/auth/auth_validation.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/labeled_field.dart';

/// Submits the dialog's input; returns the problem to show inline, or null
/// on success (the dialog then closes and reports true).
typedef AccountAction = Future<String?> Function(List<String> values);

/// AUD-48: "Change password" — current, new, and confirmation. Rules and
/// the request live in `AuthNotifier.changePassword`; this only collects
/// the fields and shows its answer. True when the password was changed.
/// Laid out to `UI-UX/screens/22-change-password-dialog` (P14-23).
Future<bool> showChangePasswordDialog(
  BuildContext context, {
  required AccountAction onSubmit,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => _PasswordFormDialog(
        title: 'Change password',
        // The changed password comes back with a fresh session, which
        // `AuthNotifier.changePassword` stores — so this device stays in.
        message:
            'You’ll stay signed in here. Every other device will be signed '
            'out.',
        labels: const [
          'Current password',
          'New password',
          'Confirm new password',
        ],
        helpers: const [
          null,
          'At least ${AuthValidation.minPasswordLength} characters.',
          null,
        ],
        confirmLabel: 'Change',
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
        helpers: const [null],
        confirmLabel: 'Delete',
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
    required this.helpers,
    required this.confirmLabel,
    required this.destructive,
    required this.onSubmit,
  });

  final String title;
  final String message;
  final List<String> labels;

  /// A rule under each field, or null; one per [labels] entry.
  final List<String?> helpers;
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
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      actionsPadding: const EdgeInsets.all(20),
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.message,
                style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
              ),
              for (final (i, label) in widget.labels.indexed)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: LabeledField(
                    label: label,
                    helper: widget.helpers[i],
                    child: TextField(
                      controller: _controllers[i],
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      enabled: !_busy,
                      autofillHints: [
                        i == 0
                            ? AutofillHints.password
                            : AutofillHints.newPassword,
                      ],
                    ),
                  ),
                ),
              if (_problem case final problem?)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: InlineAlert(
                    message: problem,
                    icon: Icons.error_outline_rounded,
                    liveRegion: true,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 48),
                  backgroundColor: widget.destructive
                      ? Theme.of(context).colorScheme.error
                      : null,
                  foregroundColor: widget.destructive
                      ? Theme.of(context).colorScheme.onError
                      : null,
                ),
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.confirmLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
