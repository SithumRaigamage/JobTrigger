import 'package:flutter/material.dart';

/// [background] with two softly tinted [color] blobs — enough to keep a
/// screen from feeling flat without hardcoding a color that would fight the
/// active theme (light surfaces stay white, dark surfaces stay dark).
/// Extracted from `LoginScreen` once `ToolSelectionScreen` needed the same
/// treatment — shared here rather than duplicated per §5 (`common_widgets/`
/// is for exactly this: presentation pieces reused across features).
class GradientBackdrop extends StatelessWidget {
  const GradientBackdrop({
    super.key,
    required this.color,
    required this.background,
    required this.child,
  });

  final Color color;
  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: background),
        Positioned(
          top: -120,
          right: -80,
          child: _Blob(color: color.withValues(alpha: 0.08), size: 320),
        ),
        Positioned(
          bottom: -140,
          left: -100,
          child: _Blob(color: color.withValues(alpha: 0.06), size: 360),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
