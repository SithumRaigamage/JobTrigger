import 'package:flutter/material.dart';

/// The app mark: a play triangle on an accent tile (`UI-UX/screens/01-login`,
/// `20-app-info`). Decorative — the screen's heading names the app.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(size * 0.29),
        ),
        child: Icon(
          Icons.play_arrow_rounded,
          color: colorScheme.onPrimary,
          size: size * 0.55,
        ),
      ),
    );
  }
}
