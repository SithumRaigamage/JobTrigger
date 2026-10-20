import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/jenkins/build_trends.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../common_widgets/glass_surface.dart';

/// US-JX-15: success rate, average and p90 duration, and a duration
/// sparkline for the last 20 or 50 finished builds. Failures are marked
/// with a ✕ shape, not just a color (NFR-A11Y-03).
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
            const SizedBox(height: 12),
            Semantics(
              label:
                  'Duration of the last ${trends.sampleSize} builds, '
                  '${trends.points.where((p) => p.failed).length} failed',
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SparklinePainter(
                    points: trends.points,
                    line: Theme.of(context).colorScheme.primary,
                    failure: AppColors.buildFailure,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Based on the last ${trends.sampleSize} finished builds'
              '${trends.sampleSize < _window ? ' loaded' : ''} · ✕ failed',
              style: textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
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
        Text(value, style: textTheme.titleMedium),
        Text(label, style: textTheme.labelSmall),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.points,
    required this.line,
    required this.failure,
  });

  final List<TrendPoint> points;
  final Color line;
  final Color failure;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxDuration = points
        .map((point) => point.durationMillis)
        .reduce((a, b) => a > b ? a : b);
    final scale = maxDuration <= 0 ? 0.0 : (size.height - 8) / maxDuration;
    final step = size.width / (points.length - 1);
    Offset at(int i) =>
        Offset(i * step, size.height - 4 - points[i].durationMillis * scale);

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    final mark = Paint()
      ..color = failure
      ..strokeWidth = 2;
    for (var i = 0; i < points.length; i++) {
      final center = at(i);
      if (points[i].failed) {
        // A ✕, so failures read without color.
        canvas
          ..drawLine(
            center - const Offset(4, 4),
            center + const Offset(4, 4),
            mark,
          )
          ..drawLine(
            center + const Offset(-4, 4),
            center + const Offset(4, -4),
            mark,
          );
      } else {
        canvas.drawCircle(center, 2, Paint()..color = line);
      }
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.points != points || old.line != line || old.failure != failure;
}
