import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../domain/sonarqube/sonarqube_analysis_status.dart';
import '../../../domain/sonarqube/sonarqube_links.dart';
import '../../../domain/sonarqube/sonarqube_measure_delta.dart';
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
import 'sonarqube_insights_notifiers.dart';
import 'sonarqube_watch_notifier.dart';
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
              ref.invalidate(
                sonarQubeAnalysisStatusNotifierProvider(project.key),
              );
              ref.invalidate(
                sonarQubeNewCodeMeasuresNotifierProvider(project.key),
              );
              ref.invalidate(
                sonarQubeMeasureDeltasNotifierProvider(project.key),
              );
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
                // US-SQ-CE-01: a scan running, queued, or the last one
                // failed. Quiet when there is nothing to say.
                ref
                    .watch(sonarQubeAnalysisStatusNotifierProvider(project.key))
                    .maybeWhen(
                      data: (status) => status.isQuiet
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: _AnalysisBanner(status: status),
                            ),
                      orElse: () => const SizedBox.shrink(),
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
                const SizedBox(height: 12),
                _GateWatchSwitch(project: project),
                const SizedBox(height: 24),
                _MeasuresSection(
                  projectKey: project.key,
                  failingKeys: failingKeys,
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
                      const Divider(height: 1),
                      _NavRow(
                        icon: Icons.show_chart_rounded,
                        label: 'Trends',
                        onTap: () => context.push(
                          AppRoutes.sonarqubeTrends,
                          extra: project,
                        ),
                      ),
                      const Divider(height: 1),
                      _NavRow(
                        icon: Icons.shield_outlined,
                        label: 'Security hotspots',
                        onTap: () => context.push(
                          AppRoutes.sonarqubeHotspots,
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

/// `US-SQ-WATCH-01`: tell me when this project's gate fails after a new
/// analysis. The story asks for the limits to be stated, not implied.
class _GateWatchSwitch extends ConsumerWidget {
  const _GateWatchSwitch({required this.project});

  final SonarQubeProject project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watching = ref
        .watch(sonarQubeWatchNotifierProvider)
        .any((watch) => watch.projectKey == project.key);
    final t = AppTokens.of(context);

    return GlassSurface.card(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        value: watching,
        onChanged: (_) async {
          final result = await ref
              .read(sonarQubeWatchNotifierProvider.notifier)
              .toggle(project);
          if (!context.mounted) return;
          final message = switch (result) {
            GateWatchResult.permissionDenied =>
              'Allow notifications in Settings to hear about a failing gate.',
            GateWatchResult.unavailableInDemo => 'Watching is off in the demo.',
            GateWatchResult.requiresPro => 'Gate notifications need Pro.',
            GateWatchResult.noCredential =>
              'Add a SonarQube token to integrate before watching.',
            GateWatchResult.added => null,
          };
          if (message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
        },
        title: const Text('Notify me when the gate fails'),
        subtitle: Text(
          'Best effort: iOS decides when background checks run. They also '
          'run every time you open the app.',
          style: DefaultTextStyle.of(
            context,
          ).style.copyWith(fontSize: 12, color: t.textMuted),
        ),
      ),
    );
  }
}

/// Measures with the Overall / New code switch (`US-SQ-QUALITY-08`) and the
/// change since the previous analysis (`US-SQ-QUALITY-09`).
class _MeasuresSection extends ConsumerWidget {
  const _MeasuresSection({required this.projectKey, required this.failingKeys});

  final String projectKey;
  final Set<String> failingKeys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(sonarQubeMeasureScopeNotifierProvider);
    final overallProvider = sonarQubeMeasuresNotifierProvider(projectKey);
    final newCodeProvider = sonarQubeNewCodeMeasuresNotifierProvider(
      projectKey,
    );
    final overall = ref.watch(overallProvider);
    final newCode = ref.watch(newCodeProvider);
    // The switch is shown only once the server has reported new-code values:
    // a server without them gets exactly the page it had before.
    final hasNewCode = newCode.value?.isNotEmpty ?? false;
    final showingNewCode = scope == SonarQubeMeasureScope.newCode && hasNewCode;
    final selected = showingNewCode ? newCode : overall;
    final deltas = ref.watch(
      sonarQubeMeasureDeltasNotifierProvider(projectKey),
    );
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scopeNotifier = ref.read(
      sonarQubeMeasureScopeNotifierProvider.notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Measures'),
        // A label plus two chips does not fit one row at ~320 dp (iPhone SE
        // with a large text size), so the chips get their own wrapping row
        // under the label.
        if (hasNewCode) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('Overall'),
                selected: !showingNewCode,
                onSelected: (_) =>
                    scopeNotifier.set(SonarQubeMeasureScope.overall),
              ),
              ChoiceChip(
                label: const Text('New code'),
                selected: showingNewCode,
                onSelected: (_) =>
                    scopeNotifier.set(SonarQubeMeasureScope.newCode),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        selected.when(
          loading: () => const _Loading(),
          error: (error, _) => ConnectionErrorView(
            message: describeError(error),
            onRetry: () => ref.invalidate(
              showingNewCode ? newCodeProvider : overallProvider,
            ),
          ),
          data: (measures) => measures.isEmpty
              ? Text(
                  showingNewCode
                      ? 'This project has no new code yet.'
                      : 'No measures reported for this project.',
                  style: textTheme.bodySmall?.copyWith(color: t.textMuted),
                )
              : showingNewCode
              ? _NewCodeMeasures(measures: measures, failingKeys: failingKeys)
              : _Measures(measures: measures, failingKeys: failingKeys),
        ),
        if (!showingNewCode)
          deltas.maybeWhen(
            data: (map) {
              final changed = [
                for (final delta in map.values)
                  if (delta.isChange) delta,
              ];
              if (changed.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _Deltas(deltas: changed),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
      ],
    );
  }
}

/// US-SQ-QUALITY-08: the new-code measures, which are different metrics from
/// the overall tiles, so they get their own rows. A metric the server did
/// not compute stays absent; nothing is invented.
class _NewCodeMeasures extends StatelessWidget {
  const _NewCodeMeasures({required this.measures, required this.failingKeys});

  final Map<String, String> measures;
  final Set<String> failingKeys;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return GlassSurface.card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final key in sonarQubeNewCodeMetricKeys)
            if (measures[key] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        sonarQubeMetricLabel(key),
                        style: textTheme.bodySmall?.copyWith(
                          color: t.textMuted,
                        ),
                      ),
                    ),
                    Text(
                      formatSonarQubeValue(key, measures[key]),
                      style: textTheme.titleSmall?.copyWith(
                        color: failingKeys.contains(key)
                            ? t.failure.foreground
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// US-SQ-QUALITY-09: what moved since the previous analysis, worse in the
/// failure colour.
class _Deltas extends StatelessWidget {
  const _Deltas({required this.deltas});

  final List<SonarQubeMeasureDelta> deltas;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return GlassSurface.card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Since the previous analysis', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final delta in deltas)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sonarQubeMetricLabel(delta.metricKey),
                      style: textTheme.bodySmall?.copyWith(color: t.textMuted),
                    ),
                  ),
                  Text(
                    delta.label,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: delta.isWorse
                          ? t.failure.foreground
                          : t.success.foreground,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// US-SQ-CE-01: a scan is running or queued, or the last one failed.
class _AnalysisBanner extends StatelessWidget {
  const _AnalysisBanner({required this.status});

  final SonarQubeAnalysisStatus status;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final pending = status.pending;
    final failure = status.lastFailure;
    final (icon, colours, title, detail) = pending != null
        ? (
            pending.isRunning
                ? Icons.autorenew_rounded
                : Icons.schedule_rounded,
            t.status(StatusTone.neutral),
            sonarQubeCePendingLabel(pending),
            'The quality gate below is from the previous analysis.',
          )
        : (
            Icons.error_outline_rounded,
            t.status(StatusTone.failure),
            'Last analysis failed',
            '${failure?.errorMessage ?? 'The server did not say why.'}'
                '${failure?.when == null ? '' : ' (${_shortTime(failure!.when!)})'}',
          );
    return GlassSurface.card(
      padding: const EdgeInsets.all(14),
      child: Semantics(
        label: '$title. $detail',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: colours.foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      color: colours.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
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

String _shortTime(DateTime when) {
  final local = when.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day}/${local.month} $hour:$minute';
}

/// US-SQ-QUALITY-07: one gate condition, passing ones included.
class _AllConditionRow extends StatelessWidget {
  const _AllConditionRow(this.condition);

  final QualityGateCondition condition;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final key = condition.metricKey;
    final actual = formatSonarQubeValue(key, condition.actual);
    final threshold = formatSonarQubeValue(key, condition.threshold);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            condition.failed
                ? Icons.cancel_rounded
                : Icons.check_circle_rounded,
            size: 16,
            color: condition.failed
                ? t.failure.foreground
                : t.success.foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${sonarQubeMetricLabel(key)}: $actual '
              '(fails when ${condition.failsWhen} $threshold)',
              style: textTheme.bodySmall?.copyWith(color: t.textMuted),
            ),
          ),
        ],
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
          // US-SQ-QUALITY-07: every condition, passing ones too, so a pass
          // that is one bug away from failing is visible.
          if (gate.conditions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'This gate has no conditions',
                style: textTheme.bodySmall?.copyWith(color: t.textMuted),
              ),
            )
          else ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Text('All conditions', style: textTheme.titleSmall),
            const SizedBox(height: 10),
            for (final condition in [
              ...failing,
              ...gate.conditions.where((c) => !c.failed),
            ])
              _AllConditionRow(condition),
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
