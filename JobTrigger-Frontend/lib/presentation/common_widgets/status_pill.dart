import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// A status as a rounded pill: the label in the status's text colour on
/// its tint (`UI-UX/README.md`, Status). The label is always there, so the
/// colour is never the only signal (NFR-A11Y-03).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  /// A pill for a Jenkins build `result`; `null` reads as running.
  factory StatusPill.forBuildResult(String? result, {Key? key}) => StatusPill(
    key: key,
    label: labelForBuildResult(result),
    tone: AppColors.toneForBuildResult(result),
  );

  final String label;
  final StatusTone tone;

  /// Human copy for a build `result`, matching the pill's tone.
  static String labelForBuildResult(String? result) =>
      switch (result?.toUpperCase()) {
        'SUCCESS' => 'Success',
        'FAILURE' => 'Failed',
        'UNSTABLE' => 'Unstable',
        'ABORTED' => 'Aborted',
        'NOT_BUILT' => 'Not built',
        null => 'Running',
        final other => other[0] + other.substring(1).toLowerCase(),
      };

  @override
  Widget build(BuildContext context) {
    final colors = AppTokens.of(context).status(tone);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.foreground),
        ),
      ),
    );
  }
}
