import 'package:flutter/material.dart';

import '../../../domain/jenkins/build_watch.dart';

/// PI-07 / IMP-11: lets the user choose which finished builds a watch
/// notifies about. Returns the chosen rule, or null when dismissed.
Future<WatchRule?> showWatchRuleSheet(
  BuildContext context, {
  required WatchRule current,
}) {
  return showModalBottomSheet<WatchRule>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Notification rule',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            RadioGroup<WatchRule>(
              groupValue: current,
              onChanged: (value) => Navigator.of(context).pop(value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final rule in WatchRule.values)
                    RadioListTile<WatchRule>(
                      value: rule,
                      title: Text(rule.label),
                      subtitle: Text(rule.description),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
