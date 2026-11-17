import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/jenkins/relative_time.dart';

/// "Saved 2h ago" (`US-SQ-OFFLINE-01`): shown above a list that is the copy
/// saved on the device because the server could not be reached, so old data is
/// never mistaken for current data.
class SonarQubeSavedBanner extends StatelessWidget {
  const SonarQubeSavedBanner({required this.savedAt, super.key});

  final DateTime savedAt;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final text = 'Saved ${relativeTime(savedAt)} · can\'t reach the server';
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: t.neutral.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 16,
              color: t.neutral.foreground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: t.neutral.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
