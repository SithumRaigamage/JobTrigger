import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/jenkins/build_trends.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../common_widgets/glass_surface.dart';

/// US-JX-15: success rate, average and p90 duration, and a duration
/// bar for each of the last 20 or 50 finished builds (P14-14,
/// `UI-UX/screens/13-job-history`). Failures are marked with a ✕ shape,
/// not just a colour (NFR-A11Y-03).
class BuildTrendsCard extends StatefulWidget {
  const BuildTrendsCard({super.key, required this.builds});

  /// Loaded history, newest first.
  final List<JenkinsBuild> builds;

  @override
  State<BuildTrendsCard> createState() => _BuildTrendsCardState();
}

class _BuildTrendsCardState extends State<BuildTrendsCard> {
  int _window = 20;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trends = buildTrends(widget.builds, window: _window);
    return GlassSurface.card(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Trends', style: textTheme.titleSmall)),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 20, label: Text('20')),
                  ButtonSegment(value: 50, label: Text('50')),
                ],
                selected: {_window},
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                onSelectionChanged: (selection) =>
                    setState(() => _window = selection.first),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (trends == null)
            Text('Not enough builds for trends', style: textTheme.bodySmall)
          else ...[
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _Stat(
                  label: 'Success',
                  value: '${(trends.successRate * 100).round()}%',
                ),
                _Stat(
                  label: 'Average',
                  value: formatBuildDuration(trends.averageMillis),
                ),
                _Stat(
                  label: 'p90',
                  value: formatBuildDuration(trends.p90Millis),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Semantics(
              label:
                  'Duration of the last ${trends.sampleSize} builds, '
                  '${trends.points.where((p) => p.failed).length} failed',
              child: SizedBox(
                height: 72,
                width: double.infinity,
                child: CustomPaint(
                  painter: _BarsPainter(
                    points: trends.points,
                    passed: AppTokens.of(context).success.dot,
                    failed: AppTokens.of(context).failure.dot,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ExcludeSemantics(
              child: Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  _Key(
                    color: AppTokens.of(context).success.dot,
                    label: 'Passed',
                  ),
                  _Key(
                    color: AppTokens.of(context).failure.dot,
                    label: 'Failed',
                    icon: Icons.close_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Based on the last ${trends.sampleSize} finished builds'
              '${trends.sampleSize < _window ? ' loaded' : ''}',
              style: textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.color, required this.label, this.icon});

  final Color color;
  final String label;

  /// The mark the chart draws over this kind of bar, if any.
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null)
        Icon(icon, size: 12, color: color)
      else
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypography.mono(textTheme.titleMedium)),
        Text(label, style: textTheme.labelSmall),
      ],
    );
  }
}

/// The duration of each build as a bar, oldest on the left, in its
/// result's colour; a failed one also gets a ✕ above it, so it reads
/// without colour (NFR-A11Y-03).
class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.points,
    required this.passed,
    required this.failed,
  });

  final List<TrendPoint> points;
  final Color passed;
  final Color failed;

  /// Room above the bars for the ✕ marks.
  static const _markRoom = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxDuration = points
        .map((point) => point.durationMillis)
        .reduce((a, b) => a > b ? a : b);
    final gap = points.length > 30 ? 2.0 : 5.0;
    final width = (size.width - gap * (points.length - 1)) / points.length;
    final room = size.height - _markRoom;
    final mark = Paint()
      ..color = failed
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final (i, point) in points.indexed) {
      final ratio = maxDuration <= 0 ? 0.0 : point.durationMillis / maxDuration;
      final height = (room * ratio).clamp(3.0, room);
      final left = i * (width + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - height, width, height),
          Radius.circular(width.clamp(0, 6) / 2),
        ),
        Paint()..color = point.failed ? failed : passed,
      );
      if (point.failed) {
        final center = Offset(left + width / 2, size.height - height - 7);
        canvas
          ..drawLine(
            center - const Offset(3, 3),
            center + const Offset(3, 3),
            mark,
          )
          ..drawLine(
            center + const Offset(-3, 3),
            center + const Offset(3, -3),
            mark,
          );
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.points != points || old.passed != passed || old.failed != failed;
}
