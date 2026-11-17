import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../../domain/sonarqube/sonarqube_analysis.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/main_scaffold.dart';
import 'sonarqube_analysis_notifier.dart';

/// When a project was analysed (`US-SQ-QUALITY-04`): a timestamped list, so
/// the user can tell whether the quality data they're reading is current.
/// An analysis is a snapshot, not a run, so rows don't open anything.
class SonarQubeAnalysisScreen extends ConsumerWidget {
  const SonarQubeAnalysisScreen({required this.project, super.key});

  final SonarQubeProject project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = sonarQubeAnalysisNotifierProvider(project.key);
    final analysesAsync = ref.watch(provider);
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text(
                        'Analysis history',
                        style: textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: analysesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => ref.read(provider.notifier).refresh(),
                    ),
                  ),
                  data: (analyses) => RefreshIndicator(
                    onRefresh: () => ref.read(provider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        16 + glassNavBarClearance(context),
                      ),
                      children: [
                        if (analyses.isEmpty)
                          const _Note('This project has not been analyzed yet.')
                        else ...[
                          for (final analysis in analyses)
                            _AnalysisTile(analysis: analysis),
                          if (analyses.length == 1)
                            const _Note(
                              'Not enough history yet to compare. Run another '
                              'analysis to see how it changes.',
                            ),
                        ],
                      ],
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

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
      ),
    );
  }
}

class _AnalysisTile extends StatelessWidget {
  const _AnalysisTile({required this.analysis});

  final SonarQubeAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final date = analysis.date;
    final when = date == null
        ? 'Unknown date'
        : '${dayLabel(date)} ${clockTime(date)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        label:
            'Analysis $when'
            '${date == null ? '' : ', ${relativeTime(date)}'}'
            '${analysis.projectVersion == null ? '' : ', version ${analysis.projectVersion}'}',
        excludeSemantics: true,
        child: GlassSurface.card(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.analytics_outlined, size: 20, color: t.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(when, style: textTheme.bodyMedium),
                    if (date != null)
                      Text(
                        relativeTime(date),
                        style: textTheme.bodySmall?.copyWith(
                          color: t.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (analysis.projectVersion != null)
                Text(
                  analysis.projectVersion!,
                  style: AppTypography.mono(
                    textTheme.bodySmall,
                  ).copyWith(fontSize: 12, color: t.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
