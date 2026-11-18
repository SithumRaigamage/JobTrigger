import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

/// Compact console toolbar. The title yields width to its actions and
/// truncates its secondary line, so the controls remain reachable on narrow
/// screens and at larger text scales.
class BuildLogToolbar extends StatelessWidget {
  const BuildLogToolbar({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.actions,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            tooltip: 'Back',
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: textTheme.titleMedium),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.mono(
                    textTheme.bodySmall,
                  ).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          for (final action in actions) action,
        ],
      ),
    );
  }
}
