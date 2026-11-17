import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// A status as an icon on its tint in a rounded square — the leading mark
/// of a pinned job, a history row, a queue entry (`UI-UX/screens/05`,
/// `08-global-history`). Each status has its own shape, so it never relies
/// on colour alone (NFR-A11Y-03). Decorative: the row it leads names the
/// status in words.
class StatusTile extends StatelessWidget {
  const StatusTile({super.key, required this.tone, this.size = 32, this.icon});

  final StatusTone tone;
  final double size;

  /// Overrides the tone's own icon, e.g. a broken link for a missing job.
  final IconData? icon;

  static IconData iconFor(StatusTone tone) => switch (tone) {
    StatusTone.running => Icons.autorenew_rounded,
    StatusTone.failure => Icons.close_rounded,
    StatusTone.success => Icons.check_rounded,
    StatusTone.unstable => Icons.warning_amber_rounded,
    StatusTone.paused => Icons.pause_rounded,
    StatusTone.neutral => Icons.remove_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = AppTokens.of(context).status(tone);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Icon(
          icon ?? iconFor(tone),
          size: size * 0.5,
          color: colors.foreground,
        ),
      ),
    );
  }
}
