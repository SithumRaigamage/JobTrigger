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
    useSafeArea: true,
    // Leave a strip of the app above the sheet: there is always somewhere
    // to tap to dismiss, and a long list never takes over the whole phone.
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text("What's new", style: textTheme.headlineSmall),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'Version ${release.version}',
            style: textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
        ),
        // Only the notes scroll. The header and the primary action stay put,
        // so there is always a visible way out (US-PROF-05).
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        Expanded(
                          child: Text(item, style: textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ),
      ],
    );
  }
}
