import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The app mark, logo Concept B (Phase 16): two pipeline stages joined to a
/// green run arrow on a navy tile, drawn from `UI-UX/brand/mark.svg`.
/// Decorative — the screen's heading names the app.
///
/// The colours are the logo's own, not the theme's. In dark mode the navy
/// tile gets a hairline outline so it doesn't sink into the dark background.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: AppLogoPainter(
          outline: dark ? AppColors.cardBorderDark : null,
        ),
      ),
    );
  }
}

/// Paints the mark on the 128-unit grid of `mark.svg`, scaled to the canvas.
@visibleForTesting
class AppLogoPainter extends CustomPainter {
  const AppLogoPainter({this.outline});

  /// Hairline around the tile, or none.
  final Color? outline;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 128;
    final tile = RRect.fromRectAndRadius(
      Offset.zero & Size.square(size.shortestSide),
      Radius.circular(28 * scale),
    );
    canvas.drawRRect(tile, Paint()..color = AppColors.logoTile);
    if (outline case final color?) {
      canvas.drawRRect(
        tile.deflate(0.5),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    canvas.save();
    canvas.scale(scale);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    stroke.color = AppColors.logoConnector;
    canvas
      ..drawLine(const Offset(37, 64), const Offset(48, 64), stroke)
      ..drawLine(const Offset(68, 64), const Offset(78, 64), stroke);

    stroke.color = AppColors.logoStage;
    canvas
      ..drawCircle(const Offset(28, 64), 9, stroke)
      ..drawCircle(const Offset(58, 64), 9, stroke);

    final run = Path()
      ..moveTo(84, 46)
      ..lineTo(84, 82)
      ..lineTo(108, 64)
      ..close();
    stroke.color = AppColors.logoRun;
    canvas
      ..drawPath(run, Paint()..color = AppColors.logoRun)
      ..drawPath(run, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(AppLogoPainter oldDelegate) =>
      oldDelegate.outline != outline;
}
