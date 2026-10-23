import 'package:flutter/material.dart';

/// The full-bleed backdrop of the auth and tool-selection screens.
///
/// P14-02: the redesign draws these screens on the plain theme background
/// (`UI-UX/screens/01-login`), so the tinted blobs this used to paint are
/// gone. Kept only until those screens are rebuilt (P14-03, P14-05), which
/// drop it for a plain `Scaffold`.
class GradientBackdrop extends StatelessWidget {
  const GradientBackdrop({super.key, required this.child});

  final Widget child;

  /// The `Scaffold` already paints the theme background, so this adds
  /// nothing over it — and must not: a `ColoredBox` ancestor would hide the
  /// ink of any `ListTile` in [child].
  @override
  Widget build(BuildContext context) => SizedBox.expand(child: child);
}
