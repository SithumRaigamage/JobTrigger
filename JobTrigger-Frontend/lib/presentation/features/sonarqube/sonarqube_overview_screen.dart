import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../domain/sonarqube/sonarqube_overview.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/section_label.dart';
import '../../navigation/main_scaffold.dart';
import 'sonarqube_credential_gate.dart';
import 'sonarqube_project_card.dart';
import 'sonarqube_projects_notifier.dart';
import 'sonarqube_summaries_notifier.dart';
import 'sonarqube_summaries_sync.dart';

/// The SonarQube tab that takes History's place (`US-SQ-OVERVIEW-01`): how
/// many projects pass their quality gate, the totals, and the projects that
/// need a look first. SonarQube reports on code, not builds, so there is no
/// run history to show.
class SonarQubeOverviewScreen extends ConsumerWidget {
  const SonarQubeOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credential = ref.watch(activeSonarQubeCredentialNotifierProvider);
    if (credential == null) return const SonarQubeCredentialGate();

    ref.watch(sonarQubeSummariesSyncProvider);
    final projectsAsync = ref.watch(sonarQubeProjectsNotifierProvider);
    final summaries = ref.watch(sonarQubeSummariesNotifierProvider);
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final projectsNotifier = ref.read(
      sonarQubeProjectsNotifierProvider.notifier,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credential.label,
                      style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text('Overview', style: textTheme.headlineLarge),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: projectsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: projectsNotifier.refresh,
                    ),
                  ),
                  data: (loaded) {
                    final overview = buildSonarQubeOverview(
                      loaded.projects,
                      summaries.byKey,
                    );
                    return RefreshIndicator(
                      onRefresh: projectsNotifier.refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          16 + glassNavBarClearance(context),
                        ),
                        children: [
                          if (loaded.projects.isEmpty)
                            const _Message('No projects found')
                          else ...[
                            _Counts(overview: overview),
                            const SizedBox(height: 12),
                            _Status(
                              overview: overview,
                              summaries: summaries,
                              onRetry: () {
                                ref.invalidate(
                                  sonarQubeSummariesNotifierProvider,
                                );
                                ref.invalidate(sonarQubeSummariesSyncProvider);
                              },
                            ),
                            if (overview.analysed > 0) ...[
                              _Totals(overview: overview),
                              const SizedBox(height: 24),
                            ],
                            _NeedsAttention(overview: overview),
                            if (overview.neverAnalysed.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              SectionLabel(
                                'Not analyzed yet',
                                trailing: '${overview.neverAnalysed.length}',
                              ),
                              const SizedBox(height: 10),
                              for (final project in overview.neverAnalysed)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: SonarQubeProjectCard(project: project),
                                ),
                            ],
                            if (loaded.hasMore)
                              _Partial(
                                loaded: loaded,
                                onLoadMore: projectsNotifier.loadMore,
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
        ),
      ),
    );
  }
}

/// One big number with its label. The column stretches so the card fills the
/// width it is given: the shared card shrinks to its content otherwise.
class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.count,
    required this.label,
    required this.tone,
  });

  final int count;
  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colour = count == 0 ? t.textMuted : t.status(tone).foreground;
    return Semantics(
      label: '$count $label',
      excludeSemantics: true,
      child: GlassSurface.card(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$count',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                color: colour,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Failing and passing always; warning and not-analyzed only when there are
/// some, so the row isn't padded with zeros.
class _Counts extends StatelessWidget {
  const _Counts({required this.overview});

  final SonarQubeOverview overview;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _CountTile(
        count: overview.failing,
        label: 'Failing',
        tone: StatusTone.failure,
      ),
      if (overview.warning > 0)
        _CountTile(
          count: overview.warning,
          label: 'Warning',
          tone: StatusTone.unstable,
        ),
      _CountTile(
        count: overview.passing,
        label: 'Passing',
        tone: StatusTone.success,
      ),
      if (overview.notAnalysed > 0)
        _CountTile(
          count: overview.notAnalysed,
          label: 'Not analyzed',
          tone: StatusTone.neutral,
        ),
    ];
    return Row(
      children: [
        for (final (i, tile) in tiles.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: tile),
        ],
      ],
    );
  }
}

/// Says that gate verdicts are still loading, or could not be, so the
/// counts above are never mistaken for the whole story.
class _Status extends StatelessWidget {
  const _Status({
    required this.overview,
    required this.summaries,
    required this.onRetry,
  });

  final SonarQubeOverview overview;
  final SonarQubeSummaries summaries;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (summaries.failure != null && overview.unknown > 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            Text(
              "Couldn't load the quality gates: "
              '${describeError(summaries.failure!)}',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (overview.unknown > 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Checking quality gates for ${overview.unknown} '
              '${overview.unknown == 1 ? 'project' : 'projects'}…',
              style: textTheme.bodySmall?.copyWith(color: t.textMuted),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Bugs, vulnerabilities and code smells summed over the analysed projects.
class _Totals extends StatelessWidget {
  const _Totals({required this.overview});

  final SonarQubeOverview overview;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    Widget column(String label, int value, {bool bad = false}) => Expanded(
      child: Semantics(
        label: '$value $label',
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              '$value',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: bad && value > 0 ? t.failure.foreground : null,
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
    return GlassSurface.card(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              column('Bugs', overview.bugs, bad: true),
              column('Vulnerabilities', overview.vulnerabilities, bad: true),
              column('Code smells', overview.codeSmells),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Across ${overview.analysed} analyzed '
            '${overview.analysed == 1 ? 'project' : 'projects'}',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NeedsAttention extends StatelessWidget {
  const _NeedsAttention({required this.overview});

  final SonarQubeOverview overview;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final projects = overview.needsAttention;
    if (projects.isEmpty) {
      // Good news only once every verdict is in: while some are still
      // loading, nothing can be said about them.
      if (overview.unknown > 0 || overview.analysed == 0) {
        return const SizedBox.shrink();
      }
      return GlassSurface.card(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: t.success.foreground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'All ${overview.analysed} analyzed '
                '${overview.analysed == 1 ? 'project passes' : 'projects pass'}'
                ' their quality gate.',
                style: textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel('Needs attention', trailing: '${projects.length}'),
        const SizedBox(height: 10),
        for (final project in projects)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SonarQubeProjectCard(project: project),
          ),
      ],
    );
  }
}

/// The overview only knows the projects loaded so far.
class _Partial extends StatelessWidget {
  const _Partial({required this.loaded, required this.onLoadMore});

  final SonarQubeProjects loaded;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Text(
            'Based on the first ${loaded.projects.length} of ${loaded.total} '
            'projects.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
          TextButton(onPressed: onLoadMore, child: const Text('Load more')),
        ],
      ),
    );
  }
}
