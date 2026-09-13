import 'package:flutter/material.dart';

/// Caps [child] at [maxWidth] and centers it horizontally. A no-op on
/// phone-width screens (iOS/Android, where the available width is usually
/// already under [maxWidth]); on wide windows (macOS desktop) it keeps
/// content from stretching edge-to-edge into an unreadable/oversized
/// layout instead of a bespoke wide-window redesign per screen.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 700});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Column count for a responsive grid, based on available width. Roughly
/// one column per [targetTileWidth], clamped to [minColumns]/[maxColumns]
/// so it never collapses to fewer columns than sensible on a phone or
/// stretches unbounded on very wide windows.
int responsiveColumnCount(
  double width, {
  double targetTileWidth = 180,
  int minColumns = 2,
  int maxColumns = 4,
}) => (width / targetTileWidth).floor().clamp(minColumns, maxColumns);
