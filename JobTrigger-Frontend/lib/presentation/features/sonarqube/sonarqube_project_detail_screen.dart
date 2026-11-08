import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../domain/sonarqube/sonarqube_links.dart';
import '../../../domain/sonarqube/sonarqube_metrics.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../../domain/sonarqube/sonarqube_quality_gate.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/external_link.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/section_label.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import 'sonarqube_last_analysis.dart';
import 'sonarqube_quality_notifiers.dart';

/// One project's code health (`US-SQ-QUALITY-01/02/05`): the quality gate
/// verdict with what broke it, the measures, the ratings and the technical
/// debt, and the way on to its issues and analysis history. Each part loads
/// and fails on its own, so a measures error never hides the gate.
class SonarQubeProjectDetailScreen extends ConsumerWidget {
  const SonarQubeProjectDetailScreen({required this.project, super.key});

  final SonarQubeProject project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateProvider = sonarQubeQualityGateNotifierProvider(project.key);
    final measuresProvider = sonarQubeMeasuresNotifierProvider(project.key);
    final credential = ref.watch(activeSonarQubeCredentialNotifierProvider);
    final gateAsync = ref.watch(gateProvider);
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    // The gate's failing metrics, so the matching tiles can be marked.
    final failingKeys = {
      for (final c
          in gateAsync.value?.failing ?? const <QualityGateCondition>[])
        c.metricKey,
    };

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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      tooltip: 'Back',
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    if (credential != null)
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded, size: 22),
                        tooltip: 'Open in SonarQube',
                        onPressed: () => openExternalLink(
                          ref,
                          sonarQubeProjectUri(credential.baseUrl, project.key),
                        ),
                      ),
                  ],
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
                const SizedBox(height: 4),
                LastAnalysisText(
                  project: project,
                  style: textTheme.bodySmall?.copyWith(color: t.textMuted),
                ),
                const SizedBox(height: 24),
                const SectionLabel('Quality gate'),
                const SizedBox(height: 8),
                gateAsync.when(
                  loading: () => const _Loading(),
                  error: (error, _) => ConnectionErrorView(
                    message: describeError(error),
                    onRetry: () => ref.invalidate(gateProvider),
                  ),
                  data: (gate) => _GateCard(gate: gate),
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
                      data: (measures) => _Measures(
                        measures: measures,
                        failingKeys: failingKeys,
                      ),
                    ),
                const SizedBox(height: 24),
                const SectionLabel('Explore'),
                const SizedBox(height: 8),
                GlassSurface.card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _NavRow(
                        icon: Icons.bug_report_outlined,
                        label: 'Issues',
                        onTap: () => context.push(
                          AppRoutes.sonarqubeIssues,
                          extra: project,
                        ),
                      ),
                      const Divider(height: 1),
                      _NavRow(
                        icon: Icons.analytics_outlined,
                        label: 'Analysis history',
                        onTap: () => context.push(
                          AppRoutes.sonarqubeAnalyses,
                          extra: project,
                        ),
                      ),
                    ],
                  ),
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

/// One tappable row of the "Explore" card.
class _NavRow extends StatelessWidget {
  const _NavRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: t.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: t.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateCard extends StatelessWidget {
  const _GateCard({required this.gate});

  final SonarQubeQualityGate gate;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final (label, tone, explanation, icon) = switch (gate.state) {
      QualityGateState.passed => (
        'Passed',
        StatusTone.success,
        'This project meets its quality gate.',
        Icons.check_rounded,
      ),
      QualityGateState.warning => (
        'Warning',
        StatusTone.unstable,
        'This project meets its quality gate with warnings.',
        Icons.priority_high_rounded,
      ),
      QualityGateState.failed => (
        'Failed',
        StatusTone.failure,
        'This project does not meet its quality gate.',
        Icons.close_rounded,
      ),
      QualityGateState.none => (
        'Not yet analyzed',
        StatusTone.neutral,
        'There is no quality gate result until the project has been '
            'analyzed.',
        Icons.hourglass_empty_rounded,
      ),
    };
    final colours = t.status(tone);
    final failing = gate.failing;
    return GlassSurface.card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Quality gate $label',
            excludeSemantics: true,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colours.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: colours.foreground),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: textTheme.titleLarge?.copyWith(
                          color: colours.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        explanation,
                        style: textTheme.bodySmall?.copyWith(
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (gate.state == QualityGateState.failed && failing.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Text('What failed', style: textTheme.titleSmall),
            const SizedBox(height: 10),
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

/// The measures, in the order that reads best (what is wrong, then how well
/// it is tested and how big it is), as a two-column grid of equal tiles.
const _tiles = <(String, IconData)>[
  ('bugs', Icons.bug_report_outlined),
  ('vulnerabilities', Icons.lock_open_rounded),
  ('code_smells', Icons.cleaning_services_outlined),
  ('coverage', Icons.pie_chart_outline_rounded),
  ('duplicated_lines_density', Icons.content_copy_outlined),
  ('ncloc', Icons.code_rounded),
];

class _Measures extends StatelessWidget {
  const _Measures({required this.measures, required this.failingKeys});

  final Map<String, String> measures;
  final Set<String> failingKeys;

  @override
  Widget build(BuildContext context) {
    // Ratings and debt appear only when the server computed them.
    final ratings = [
      for (final (key, label) in const [
        ('reliability_rating', 'Reliability'),
        ('security_rating', 'Security'),
        ('sqale_rating', 'Maintainability'),
      ])
        if (measures[key] != null) (key, label),
    ];
    final debt = measures['sqale_index'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (var j = i; j < i + 2; j++) ...[
                if (j > i) const SizedBox(width: 10),
                Expanded(
                  child: _MeasureTile(
                    icon: _tiles[j].$2,
                    label: sonarQubeMetricLabel(_tiles[j].$1),
                    value: formatSonarQubeValue(
                      _tiles[j].$1,
                      measures[_tiles[j].$1],
                    ),
                    failing: failingKeys.contains(_tiles[j].$1),
                  ),
                ),
              ],
            ],
          ),
        ],
        if (ratings.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (i, (key, label)) in ratings.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _RatingTile(
                    label: label,
                    letter: formatSonarQubeValue(key, measures[key]),
                    failing: failingKeys.contains(key),
                  ),
                ),
              ],
            ],
          ),
        ],
        if (debt != null) ...[
          const SizedBox(height: 10),
          _MeasureTile(
            icon: Icons.hourglass_bottom_rounded,
            label: 'Technical debt: time to fix every issue',
            value: formatSonarQubeValue('sqale_index', debt),
            failing: failingKeys.contains('sqale_index'),
          ),
        ],
      ],
    );
  }
}

/// A measure's icon, value and name. The column stretches so the card fills
/// the width it is given: the shared card shrinks to its content otherwise,
/// which is what made the old tiles uneven.
class _MeasureTile extends StatelessWidget {
  const _MeasureTile({
    required this.icon,
    required this.label,
    required this.value,
    this.failing = false,
  });

  final IconData icon;
  final String label;
  final String value;

  /// The quality gate failed on this measure.
  final bool failing;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final accent = failing ? t.failure.foreground : null;
    return Semantics(
      label:
          '${value == '—' ? '$label: no data' : '$label: $value'}'
          '${failing ? ', failed the quality gate' : ''}',
      excludeSemantics: true,
      child: GlassSurface.card(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(icon, size: 18, color: accent ?? t.textMuted),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
            const SizedBox(height: 2),
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

/// A rating as its letter in a coloured circle: A and B are good, C is a
/// warning, D and E are bad.
class _RatingTile extends StatelessWidget {
  const _RatingTile({
    required this.label,
    required this.letter,
    this.failing = false,
  });

  final String label;
  final String letter;
  final bool failing;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final tone = switch (letter) {
      'A' || 'B' => StatusTone.success,
      'C' => StatusTone.unstable,
      'D' || 'E' => StatusTone.failure,
      _ => StatusTone.neutral,
    };
    final colours = t.status(tone);
    return Semantics(
      label:
          '$label rating $letter'
          '${failing ? ', failed the quality gate' : ''}',
      excludeSemantics: true,
      child: GlassSurface.card(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colours.background,
                  shape: BoxShape.circle,
                  border: failing
                      ? Border.all(color: t.failure.dot, width: 2)
                      : null,
                ),
                child: Text(
                  letter,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colours.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
