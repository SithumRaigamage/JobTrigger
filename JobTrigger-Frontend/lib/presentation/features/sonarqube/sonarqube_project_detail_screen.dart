import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/sonarqube/sonarqube_metrics.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../../domain/sonarqube/sonarqube_quality_gate.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/section_label.dart';
import '../../common_widgets/status_pill.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import 'sonarqube_quality_notifiers.dart';

/// One project's code health: the quality gate verdict with the conditions
/// that broke it (`US-SQ-QUALITY-01`) and the key measures
/// (`US-SQ-QUALITY-02`). Each part loads and fails on its own, so a measures
/// error never hides the gate.
class SonarQubeProjectDetailScreen extends ConsumerWidget {
  const SonarQubeProjectDetailScreen({required this.project, super.key});

  final SonarQubeProject project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateProvider = sonarQubeQualityGateNotifierProvider(project.key);
    final measuresProvider = sonarQubeMeasuresNotifierProvider(project.key);
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(gateProvider);
              ref.invalidate(measuresProvider);
              await Future.wait([
                ref.read(gateProvider.future).then((_) {}, onError: (_) {}),
                ref.read(measuresProvider.future).then((_) {}, onError: (_) {}),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                16 + glassNavBarClearance(context),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(project.name, style: textTheme.headlineMedium),
                ),
                const SizedBox(height: 4),
                Text(
                  project.key,
                  style: AppTypography.mono(
                    textTheme.bodySmall,
                  ).copyWith(fontSize: 12, color: t.textMuted),
                ),
                const SizedBox(height: 20),
                const SectionLabel('Quality gate'),
                const SizedBox(height: 8),
                ref
                    .watch(gateProvider)
                    .when(
                      loading: () => const _Loading(),
                      error: (error, _) => ConnectionErrorView(
                        message: describeError(error),
                        onRetry: () => ref.invalidate(gateProvider),
                      ),
                      data: (gate) => _GateCard(gate: gate),
                    ),
                const SizedBox(height: 24),
                GlassSurface.card(
                  padding: const EdgeInsets.all(16),
                  onTap: () =>
                      context.push(AppRoutes.sonarqubeIssues, extra: project),
                  child: Row(
                    children: [
                      const Icon(Icons.bug_report_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Issues', style: textTheme.titleSmall),
                      ),
                      Icon(Icons.chevron_right_rounded, color: t.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GlassSurface.card(
                  padding: const EdgeInsets.all(16),
                  onTap: () =>
                      context.push(AppRoutes.sonarqubeAnalyses, extra: project),
                  child: Row(
                    children: [
                      const Icon(Icons.analytics_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Analysis history',
                          style: textTheme.titleSmall,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: t.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionLabel('Measures'),
                const SizedBox(height: 8),
                ref
                    .watch(measuresProvider)
                    .when(
                      loading: () => const _Loading(),
                      error: (error, _) => ConnectionErrorView(
                        message: describeError(error),
                        onRetry: () => ref.invalidate(measuresProvider),
                      ),
                      data: (measures) => _MeasuresGrid(measures: measures),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _GateCard extends StatelessWidget {
  const _GateCard({required this.gate});

  final SonarQubeQualityGate gate;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final (label, tone, explanation) = switch (gate.state) {
      QualityGateState.passed => (
        'Passed',
        StatusTone.success,
        'This project meets its quality gate.',
      ),
      QualityGateState.warning => (
        'Warning',
        StatusTone.unstable,
        'This project meets its quality gate with warnings.',
      ),
      QualityGateState.failed => (
        'Failed',
        StatusTone.failure,
        'This project does not meet its quality gate.',
      ),
      QualityGateState.none => (
        'Not yet analyzed',
        StatusTone.neutral,
        'There is no quality gate result until the project has been '
            'analyzed.',
      ),
    };
    final failing = gate.failing;
    return GlassSurface.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Quality gate $label',
            excludeSemantics: true,
            child: Row(
              children: [
                StatusPill(label: label, tone: tone),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    explanation,
                    style: textTheme.bodySmall?.copyWith(color: t.textMuted),
                  ),
                ),
              ],
            ),
          ),
          if (gate.state == QualityGateState.failed && failing.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('What failed', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final condition in failing) _ConditionRow(condition),
          ],
        ],
      ),
    );
  }
}

/// "Coverage on new code: 62.1% — fails when below 80%".
class _ConditionRow extends StatelessWidget {
  const _ConditionRow(this.condition);

  final QualityGateCondition condition;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final key = condition.metricKey;
    final label = sonarQubeMetricLabel(key);
    final actual = formatSonarQubeValue(key, condition.actual);
    final threshold = formatSonarQubeValue(key, condition.threshold);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label:
            '$label is $actual. Fails when ${condition.failsWhen} $threshold.',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.close_rounded, size: 18, color: t.failure.dot),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label: $actual',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Fails when ${condition.failsWhen} $threshold',
                    style: textTheme.bodySmall?.copyWith(color: t.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasuresGrid extends StatelessWidget {
  const _MeasuresGrid({required this.measures});

  final Map<String, String> measures;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final tileWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final key in sonarQubeMeasureKeys)
              SizedBox(
                width: tileWidth,
                child: _MeasureTile(
                  label: sonarQubeMetricLabel(key),
                  value: formatSonarQubeValue(key, measures[key]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MeasureTile extends StatelessWidget {
  const _MeasureTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: value == '—' ? '$label: no data' : '$label: $value',
      excludeSemantics: true,
      child: GlassSurface.card(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
