import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// A tinted, icon-led note inside a screen: a login error, a failed stage,
/// a cleartext warning (`UI-UX/screens/01-login`, `14-build-detail`,
/// `19-open-link`). Announced as it appears ([liveRegion]) when it reports
/// something that just happened.
class InlineAlert extends StatelessWidget {
  const InlineAlert({
    super.key,
    required this.message,
    this.title,
    this.tone = StatusTone.failure,
    this.icon = Icons.warning_amber_rounded,
    this.liveRegion = false,
  });

  final String message;
  final String? title;
  final StatusTone tone;
  final IconData icon;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final colors = AppTokens.of(context).status(tone);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: liveRegion,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 18, color: colors.foreground),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: textTheme.titleSmall?.copyWith(
                          color: colors.foreground,
                        ),
                      ),
                    Text(
                      message,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colors.foreground,
                      ),
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
}
