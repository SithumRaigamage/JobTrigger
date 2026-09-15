import 'package:flutter/material.dart';

/// Dims [child] and shows a centered spinner while [isLoading] is true,
/// blocking interaction underneath. No direct SwiftUI equivalent — the old
/// app scattered inline `ProgressView()`s; this centralizes the pattern.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
