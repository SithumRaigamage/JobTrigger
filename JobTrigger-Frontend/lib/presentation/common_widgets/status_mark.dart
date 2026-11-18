import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'status_tile.dart';

/// PI-06 / IMP-51: a status as a **shape and words**, for the few places a
/// status still relied on colour alone (the Home server chip, Jenkins stage
/// segments and GitHub step segments). The icon is the same distinct one
/// [StatusTile] uses and [label] is always rendered, so neither colour
/// vision nor a colour-blind mode changes the meaning (NFR-A11Y-03).
///
/// [StatusPill] and [StatusTile] already carry a label in their own row and
/// are left as they are; this is for a bare dot/bar that needs one.
class StatusMark extends StatelessWidget {
  const StatusMark({
    super.key,
    required this.tone,
    required this.label,
    this.icon,
    this.iconSize = 16,
    this.spacing = 4,
    this.labelStyle,
    this.semanticsLabel,
  });

  final StatusTone tone;

  /// Shown as text, e.g. "Online", "Passed", "Skipped".
  final String label;

  /// Overrides the tone's own shape.
  final IconData? icon;
  final double iconSize;
  final double spacing;
  final TextStyle? labelStyle;

  /// Overrides what a screen reader announces; defaults to [label].
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppTokens.of(context).status(tone);
    final style =
        labelStyle ??
        Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colors.foreground);
    // A single rich-text run (rather than a Row) ellipsizes correctly in a
    // fixed-width segment and needs no bounded flex constraints.
    return Semantics(
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                icon ?? StatusTile.iconFor(tone),
                size: iconSize,
                color: colors.foreground,
              ),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: SizedBox(width: spacing),
            ),
            TextSpan(text: label),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
