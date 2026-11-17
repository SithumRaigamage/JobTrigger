import 'package:flutter/material.dart';

/// The shared confirmation step for state-changing actions against a live
/// CI system: trigger, cancel (AUD-08; US-JOB-02/03/05), input approval
/// (US-PIPE-05), and the admin-flavoured actions in epic JX.
///
/// Resolves `true` only on an explicit tap of [confirmLabel]; dismissing
/// the dialog any other way counts as "no". [destructive] styles the
/// confirm action with the error color (cancel, abort, disable).
///
/// When [requiredPhrase] is supplied (PI-02/IMP-24, protected actions), a
/// text field is shown and the confirm button stays disabled until that exact
/// string is typed. Existing single-step callers pass nothing and are
/// unchanged.
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  Widget? details,
  String? requiredPhrase,

  /// Label for the negative action. Most callers keep the default "Cancel";
  /// cancel-run uses "Keep running" so declining reads unambiguously.
  String cancelLabel = 'Cancel',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _ConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: destructive,
      details: details,
      requiredPhrase: requiredPhrase,
      cancelLabel: cancelLabel,
    ),
  );
  return confirmed ?? false;
}

class _ConfirmationDialog extends StatefulWidget {
  const _ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.destructive,
    required this.details,
    required this.requiredPhrase,
    required this.cancelLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;
  final Widget? details;
  final String? requiredPhrase;
  final String cancelLabel;

  @override
  State<_ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<_ConfirmationDialog> {
  final _controller = TextEditingController();
  String _typed = '';

  bool get _canConfirm =>
      widget.requiredPhrase == null || _typed == widget.requiredPhrase;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final phrase = widget.requiredPhrase;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message),
            if (phrase != null) ...[
              const SizedBox(height: 12),
              Text('Type "$phrase" to confirm.'),
              const SizedBox(height: 8),
              TextField(
                key: const Key('confirmation_phrase_field'),
                controller: _controller,
                onChanged: (value) => setState(() => _typed = value),
                decoration: const InputDecoration(
                  labelText: 'Confirm name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (widget.details != null) ...[
              const SizedBox(height: 12),
              widget.details!,
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          key: const Key('confirmation_confirm_button'),
          style: widget.destructive
              ? FilledButton.styleFrom(backgroundColor: colorScheme.error)
              : null,
          onPressed: _canConfirm
              ? () => Navigator.of(context).pop(true)
              : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
