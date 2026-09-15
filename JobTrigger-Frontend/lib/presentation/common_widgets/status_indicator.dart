import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Ported from `Shared/Navigation/StatusIndicator.swift`. Pulses while the
/// job is building (Jenkins' `_anime` color suffix).
class StatusIndicator extends StatefulWidget {
  const StatusIndicator({super.key, required this.color});

  final String? color;

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  bool get _isAnimating => AppColors.isJobColorAnimating(widget.color);

  @override
  void initState() {
    super.initState();
    if (_isAnimating) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isAnimating && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!_isAnimating && _controller.isAnimating) {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forJobColor(widget.color);

    return Semantics(
      label: AppColors.describeJobColor(widget.color),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = _isAnimating ? _controller.value : 0.0;
          return SizedBox(
            width: 16,
            height: 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1.0 + (0.4 * pulse),
                  child: Opacity(
                    opacity: (0.2 - (0.1 * pulse)).clamp(0.0, 1.0),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color, blurRadius: pulse > 0.5 ? 6 : 4),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
