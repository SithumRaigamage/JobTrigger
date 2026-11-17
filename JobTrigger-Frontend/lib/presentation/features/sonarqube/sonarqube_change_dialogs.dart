import 'package:flutter/material.dart';

/// Every change to SonarQube data asks first (batch 7), the way Jenkins
/// trigger and cancel do. Says what will happen and that it reaches the
/// server; nothing on screen changes until the server has answered.
Future<bool> confirmSonarQubeChange(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;

/// Asks for a free-text value (a login, a comment). Null when cancelled.
Future<String?> askSonarQubeText(
  BuildContext context, {
  required String title,
  required String label,
  String? hint,
  String confirmLabel = 'Continue',
  int maxLines = 1,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: maxLines,
        minLines: maxLines == 1 ? 1 : 3,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  controller.dispose();
  return (result == null || result.isEmpty) ? null : result;
}

/// A bottom sheet of choices; the chosen value, or null.
Future<T?> pickSonarQubeChoice<T>(
  BuildContext context, {
  required String title,
  required List<(String label, T value)> choices,
}) => showModalBottomSheet<T>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        // Scrolls: a server can have hundreds of projects to choose from.
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final (label, value) in choices)
                ListTile(
                  title: Text(label),
                  onTap: () => Navigator.of(context).pop(value),
                ),
            ],
          ),
        ),
      ],
    ),
  ),
);
