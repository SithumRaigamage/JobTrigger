import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// A small uppercase heading over a group of rows ("PINNED", "ALL JOBS")
/// — 12/600 with 0.06em tracking in the muted colour (`UI-UX/README.md`).
/// Exposed to screen readers as a header.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.icon, this.trailing});

  final String text;
  final IconData? icon;

  /// Optional right-aligned detail, e.g. a count.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final muted = AppTokens.of(context).textMuted;
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: muted, letterSpacing: 0.72);
    return Semantics(
      header: true,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: muted),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              text.toUpperCase(),
              // Read in its natural case: some screen readers spell out
              // all-caps text letter by letter.
              semanticsLabel: text,
              style: style,
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: style?.copyWith(
                letterSpacing: 0,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
