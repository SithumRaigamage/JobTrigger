import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/onboarding/whats_new.dart';

/// PI-10 / IMP-65: the "What's new" sheet, shown once per install after an
/// update and opened any time from Profile.
Future<void> showWhatsNewSheet(
  BuildContext context, {
  required String version,
}) {
  final release = whatsNewFor(version) ?? whatsNewReleases.last;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => WhatsNewSheet(release: release),
  );
}

class WhatsNewSheet extends StatelessWidget {
  const WhatsNewSheet({super.key, required this.release});

  final WhatsNewRelease release;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("What's new", style: textTheme.headlineSmall),
            const SizedBox(height: 2),
            Text(
              'Version ${release.version}',
              style: textTheme.bodySmall?.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: 16),
            for (final item in release.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: t.success.dot,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item, style: textTheme.bodyMedium)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }
}
