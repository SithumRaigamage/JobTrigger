import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../../domain/sonarqube/sonarqube_project_summary.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/status_pill.dart';
import '../../navigation/app_routes.dart';
import 'sonarqube_gate_style.dart';
import 'sonarqube_last_analysis.dart';
import 'sonarqube_summaries_notifier.dart';

/// One project: its name and key, its quality-gate verdict, the headline
/// numbers, and when it was last analysed. A tap opens the project.
class SonarQubeProjectCard extends ConsumerWidget {
  const SonarQubeProjectCard({required this.project, super.key});

  final SonarQubeProject project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final summary = ref.watch(
      sonarQubeSummariesNotifierProvider.select((s) => s.byKey[project.key]),
    );
    return Semantics(
      button: true,
      label:
          '${project.name}, ${project.key}'
          '${summary == null ? '' : ', quality gate ${gateLabel(summary.gate)}'}',
      excludeSemantics: true,
      child: GlassSurface.card(
        padding: const EdgeInsets.all(16),
        onTap: () => context.push(AppRoutes.sonarqubeProject, extra: project),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                ),
                if (summary != null) ...[
                  const SizedBox(width: 8),
                  StatusPill(
                    label: gateLabel(summary.gate),
                    tone: gateTone(summary.gate),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              project.key,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.mono(
                textTheme.bodySmall,
              ).copyWith(fontSize: 12, color: t.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (summary != null) Expanded(child: _Stats(summary: summary)),
                if (summary == null) const Spacer(),
                LastAnalysisText(
                  project: project,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: t.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bugs, vulnerabilities, code smells and coverage as four small figures. A
/// count above zero for bugs or vulnerabilities is drawn in the failure
/// colour; a figure the server did not compute is a dash, not a zero.
class _Stats extends StatelessWidget {
  const _Stats({required this.summary});

  final SonarQubeProjectSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final bad = t.failure.foreground;
    String count(int? n) => n == null ? '—' : '$n';
    final coverage = summary.coverage;
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        _Stat(
          icon: Icons.bug_report_outlined,
          text: count(summary.bugs),
          label: 'bugs',
          color: (summary.bugs ?? 0) > 0 ? bad : null,
        ),
        _Stat(
          icon: Icons.lock_open_rounded,
          text: count(summary.vulnerabilities),
          label: 'vulnerabilities',
          color: (summary.vulnerabilities ?? 0) > 0 ? bad : null,
        ),
        _Stat(
          icon: Icons.cleaning_services_outlined,
          text: count(summary.codeSmells),
          label: 'code smells',
        ),
        _Stat(
          icon: Icons.pie_chart_outline_rounded,
          text: coverage == null ? '—' : '${coverage.round()}%',
          label: 'coverage',
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.text,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String text;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final tone = color ?? t.textSecondary;
    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: tone),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: tone,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
