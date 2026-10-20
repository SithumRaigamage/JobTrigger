import 'package:flutter/material.dart';

/// The shared confirmation step for state-changing actions against a live
/// CI system: trigger, cancel (AUD-08; US-JOB-02/03/05), input approval
/// (US-PIPE-05), and the admin-flavoured actions in epic JX.
///
/// Resolves `true` only on an explicit tap of [confirmLabel]; dismissing
/// the dialog any other way counts as "no". [destructive] styles the
/// confirm action with the error color (cancel, abort, disable).
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
  Widget? details,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (details != null) ...[const SizedBox(height: 12), details],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: destructive
                ? TextButton.styleFrom(foregroundColor: colorScheme.error)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
