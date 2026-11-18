import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_measure_history.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/main_scaffold.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../common_widgets/tool_server_credential_header.dart';
import '../../../core/error/error_message.dart';

part 'sonarqube_trends_screen.g.dart';

/// One measure's history for a project (`US-SQ-QUALITY-11`).
@riverpod
Future<SonarQubeMeasureHistory> sonarQubeMeasureHistory(
  Ref ref,
  String projectKey,
  String metric,
) async {
  final result = await ref
      .watch(sonarQubeRepositoryProvider)
      .fetchMeasureHistory(projectKey, metric);
  return result.fold((history) => history, (failure) => throw failure);
}

/// `US-SQ-QUALITY-11`: how a measure moved over the project's analyses, as a
/// small line chart drawn by hand (no chart library in the stack), with the
/// touched point's value and date spelled out as text.
class SonarQubeTrendsScreen extends ConsumerStatefulWidget {
  const SonarQubeTrendsScreen({required this.project, super.key});

  final SonarQubeProject project;

  @override
  ConsumerState<SonarQubeTrendsScreen> createState() =>
      _SonarQubeTrendsScreenState();
}

class _SonarQubeTrendsScreenState extends ConsumerState<SonarQubeTrendsScreen> {
  SonarQubeTrendMetric _metric = sonarQubeTrendMetrics.first;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(
      sonarQubeMeasureHistoryProvider(widget.project.key, _metric.metric),
    );
    final credential = ref.watch(activeSonarQubeCredentialNotifierProvider);
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (credential != null)
                SonarQubeCredentialHeader(
                  credential: credential,
                  onSwitch: (chosen) => ref
                      .read(activeSonarQubeCredentialNotifierProvider.notifier)
                      .setActiveCredential(chosen),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      tooltip: 'Back',
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.name,
                            style: textTheme.bodySmall?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                          Semantics(
                            header: true,
                            child: Text(
                              'Trends',
                              style: textTheme.headlineMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final metric in sonarQubeTrendMetrics)
                      ChoiceChip(
                        label: Text(metric.label),
                        selected: metric.metric == _metric.metric,
                        onSelected: (_) => setState(() {
                          _metric = metric;
                          _selected = null;
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: historyAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref.invalidate(
                        sonarQubeMeasureHistoryProvider(
                          widget.project.key,
                          _metric.metric,
                        ),
                      ),
                    ),
                  ),
                  data: (history) => history.hasEnoughHistory
                      ? _Chart(
                          history: history,
                          selected: _selected,
                          onSelected: (index) =>
                              setState(() => _selected = index),
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Not enough history yet',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: t.textMuted,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.history,
    required this.selected,
    required this.onSelected,
  });

  final SonarQubeMeasureHistory history;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final point = selected == null ? history.latest : history.points[selected!];
    final line = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + glassNavBarClearance(context),
      ),
      children: [
        GlassSurface.card(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => onSelected(
                  nearestSonarQubePointIndex(
                    history.points,
                    details.localPosition.dx,
                    width,
                  ),
                ),
                child: Semantics(
                  label:
                      '${history.metric} chart, '
                      'lowest ${history.format(history.lowest?.value ?? 0)} on '
                      '${history.lowest?.dateLabel ?? ''}, '
                      'highest ${history.format(history.highest?.value ?? 0)} on '
                      '${history.highest?.dateLabel ?? ''}',
                  child: SizedBox(
                    width: width,
                    height: 180,
                    child: CustomPaint(
                      painter: SonarQubeTrendPainter(
                        history: history,
                        selected: selected,
                        line: line,
                        grid: t.textMuted.withValues(alpha: 0.3),
                        labelStyle: AppTypography.mono(
                          textTheme.bodySmall,
                        ).copyWith(fontSize: 10, color: t.textMuted),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (point != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${point.dateLabel} · ${history.format(point.value)}',
              key: const ValueKey('trend-readout'),
              style: textTheme.titleMedium,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Tap the line to read a point. '
            'Lowest ${history.format(history.lowest?.value ?? 0)}, '
            'highest ${history.format(history.highest?.value ?? 0)} '
            'over ${history.points.length} analyses.',
            style: textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
        ),
      ],
    );
  }
}

/// The line, drawn by hand: no chart library, and every value it shows is
/// also written as text so it is readable without colour.
class SonarQubeTrendPainter extends CustomPainter {
  SonarQubeTrendPainter({
    required this.history,
    required this.selected,
    required this.line,
    required this.grid,
    required this.labelStyle,
  });

  final SonarQubeMeasureHistory history;
  final int? selected;
  final Color line;
  final Color grid;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final points = history.points;
    if (points.length < 2) return;
    final values = [for (final p in points) p.value.toDouble()];
    var low = values.reduce((a, b) => a < b ? a : b);
    var high = values.reduce((a, b) => a > b ? a : b);
    if (high == low) {
      high += 1;
      low -= 1;
    }
    const leftPad = 34.0;
    final chart = Rect.fromLTRB(leftPad, 8, size.width, size.height - 18);
    double x(int i) => chart.left + chart.width * i / (points.length - 1);
    double y(double v) =>
        chart.bottom - chart.height * (v - low) / (high - low);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    final text = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i <= 3; i++) {
      final value = low + (high - low) * i / 3;
      final dy = y(value);
      canvas.drawLine(
        Offset(chart.left, dy),
        Offset(chart.right, dy),
        gridPaint,
      );
      text
        ..text = TextSpan(text: history.format(value), style: labelStyle)
        ..layout();
      text.paint(canvas, Offset(0, dy - text.height / 2));
    }

    final linePath = Path()..moveTo(x(0), y(values.first));
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(
        Offset(x(i), y(values[i])),
        i == selected ? 5 : 2.5,
        Paint()..color = line,
      );
    }

    text
      ..text = TextSpan(text: points.first.dateLabel, style: labelStyle)
      ..layout();
    text.paint(canvas, Offset(chart.left, chart.bottom + 4));
    text
      ..text = TextSpan(text: points.last.dateLabel, style: labelStyle)
      ..layout();
    text.paint(canvas, Offset(chart.right - text.width, chart.bottom + 4));
  }

  @override
  bool shouldRepaint(SonarQubeTrendPainter oldDelegate) =>
      oldDelegate.history != history || oldDelegate.selected != selected;
}
