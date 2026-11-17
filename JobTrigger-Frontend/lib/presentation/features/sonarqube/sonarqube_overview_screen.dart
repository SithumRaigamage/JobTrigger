import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../data/credentials/sonarqube_credentials_notifier.dart';
import '../../../domain/credential/sonarqube_credential.dart';
import '../../../domain/sonarqube/sonarqube_overview.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/data_freshness.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/section_label.dart';
import '../../navigation/app_routes.dart';
import '../../navigation/main_scaffold.dart';
import 'sonarqube_credential_gate.dart';
import 'sonarqube_project_card.dart';
import 'sonarqube_projects_notifier.dart';
import 'sonarqube_overview_trend_notifier.dart';
import 'sonarqube_pins_notifier.dart';
import 'sonarqube_saved_banner.dart';
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _CredentialSelector(
                    credential: credential,
                    onSwitch: (chosen) => ref
                        .read(
                          activeSonarQubeCredentialNotifierProvider.notifier,
                        )
                        .setActiveCredential(chosen),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                header: true,
                child: Text('Overview', style: textTheme.headlineLarge),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.assignment_ind_outlined,
                        label: 'My issues',
                        onTap: () =>
                            context.push(AppRoutes.sonarqubeMyIssues),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.search_rounded,
                        label: 'Search issues',
                        onTap: () =>
                            context.push(AppRoutes.sonarqubeIssueSearch),
                      ),
                    ),
                  ],
                ),
              ),
              // PI-05: when these numbers were last loaded. The cached
              // "Saved …" copy stays with SonarQubeSavedBanner in the body.
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: DataFreshnessBanner(
                  freshnessKey: sonarqubeProjectsFreshnessKey,
                  showOffline: false,
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
                      pinned: ref.watch(sonarQubePinnedKeysProvider),
                    );
                    // US-SQ-OVERVIEW-02: compare with, and add to, the snapshots
                    // kept on this device once every gate verdict has arrived.
                    if (overview.unknown == 0 &&
                        loaded.projects.isNotEmpty &&
                        loaded.savedAt == null) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => ref
                            .read(
                              sonarQubeOverviewTrendNotifierProvider.notifier,
                            )
                            .record(overview),
                      );
                    }
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
                          if (loaded.savedAt != null)
                            SonarQubeSavedBanner(savedAt: loaded.savedAt!),
                          if (loaded.projects.isEmpty)
                            const _Message('No projects found')
                          else ...[
                            _Counts(overview: overview),
                            const SizedBox(height: 8),
                            _TrendLine(
                              state: ref.watch(
                                sonarQubeOverviewTrendNotifierProvider,
                              ),
                            ),
                            const SizedBox(height: 4),
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

/// One count as a colored pill, matching the Jenkins Home design's
/// Running/Failing/Passing cards: tinted background, status-coloured number
/// and label. A zero count fades to neutral so a clean board isn't a wall of
/// red.
class _PillCount extends StatelessWidget {
  const _PillCount({
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
    final colours = t.status(tone);
    final isZero = count == 0;
    final fg = isZero ? t.textMuted : colours.foreground;
    return Semantics(
      label: '$count $label',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: isZero ? t.raised : colours.background,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$count',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// A quick action on the Overview, styled like the count pills so the row
/// reads as one family. These are the entry points for `US-SQ-ISSUES-01`
/// (what is assigned to you) and `US-SQ-ISSUES-03` (find an issue by rule,
/// tag, file or key).
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return GlassSurface.card(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 22, color: t.textSecondary),
          const SizedBox(height: 6),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: t.textSecondary),
          ),
        ],
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
      _PillCount(
        count: overview.failing,
        label: 'Failing',
        tone: StatusTone.failure,
      ),
      if (overview.warning > 0)
        _PillCount(
          count: overview.warning,
          label: 'Warning',
          tone: StatusTone.unstable,
        ),
      _PillCount(
        count: overview.passing,
        label: 'Passing',
        tone: StatusTone.success,
      ),
      if (overview.notAnalysed > 0)
        _PillCount(
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

/// The active SonarQube credential, tappable to drop down the saved ones and
/// switch in place — the same pattern as Jenkins Home's server chip (`P19-07`).
/// Switching only changes the SonarQube credential, never another tool's.
class _CredentialSelector extends ConsumerWidget {
  const _CredentialSelector({
    required this.credential,
    required this.onSwitch,
  });

  final SonarQubeCredential credential;
  final ValueChanged<SonarQubeCredential> onSwitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final saved = ref.watch(sonarQubeCredentialsNotifierProvider).value;
    final credentials = saved == null || !saved.any((c) => c.id == credential.id)
        ? [credential, ...?saved]
        : saved;
    return Semantics(
      button: true,
      label: 'SonarQube ${credential.label}. Switch credential',
      excludeSemantics: true,
      child: Material(
        color: t.card,
        shape: StadiumBorder(side: BorderSide(color: t.cardBorder)),
        child: PopupMenuButton<String>(
          position: PopupMenuPosition.under,
          borderRadius: BorderRadius.circular(22),
          onSelected: (id) {
            if (id == _manageCredentialsAction) {
              context.go(AppRoutes.settings);
              return;
            }
            final chosen = credentials.firstWhere((c) => c.id == id);
            if (chosen.id == credential.id) return;
            onSwitch(chosen);
          },
          itemBuilder: (context) => [
            for (final option in credentials)
              PopupMenuItem<String>(
                value: option.id,
                child: _CredentialOption(
                  credential: option,
                  isActive: option.id == credential.id,
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: _manageCredentialsAction,
              child: ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Manage credentials…'),
              ),
            ),
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    size: 16,
                    color: t.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      credential.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: t.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sentinel returned by "Manage credentials…" — opens Settings instead of
/// switching.
const _manageCredentialsAction = '__manage_credentials__';

/// One saved credential in the dropdown, with a check on the active one and
/// its URL underneath.
class _CredentialOption extends StatelessWidget {
  const _CredentialOption({
    required this.credential,
    required this.isActive,
  });

  final SonarQubeCredential credential;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      selected: isActive,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: isActive
                ? Icon(Icons.check_rounded, size: 20, color: t.success.dot)
                : null,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  credential.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  credential.baseUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: t.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
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

/// "Since you last looked" (`US-SQ-OVERVIEW-02`). The label is deliberately
/// not "over time": SonarQube keeps no portfolio history, so this is only
/// what this device saw, and the first visit says the trend starts now.
class _TrendLine extends StatelessWidget {
  const _TrendLine({required this.state});

  final SonarQubeTrendState state;

  @override
  Widget build(BuildContext context) {
    if (!state.recorded) return const SizedBox.shrink();
    final t = AppTokens.of(context);
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: t.textMuted);
    final trend = state.trend;
    if (trend == null) {
      return Text(
        'The trend starts now: this device keeps a count each time you look, '
        'so the next visit can show the change.',
        textAlign: TextAlign.center,
        style: style,
      );
    }
    final change = trend.failingChange;
    final what = switch (change) {
      0 => 'Same number failing as',
      > 0 => '$change more failing than',
      _ => '${-change} fewer failing than',
    };
    final colour = change > 0
        ? t.status(StatusTone.failure).foreground
        : change < 0
        ? t.status(StatusTone.success).foreground
        : t.textMuted;
    return Semantics(
      label: '$what ${_ago(trend.since)}',
      child: Text(
        '$what ${_ago(trend.since)}',
        textAlign: TextAlign.center,
        style: style?.copyWith(color: colour, fontWeight: FontWeight.w600),
      ),
    );
  }

  static String _ago(DateTime then) {
    final gap = DateTime.now().difference(then);
    if (gap.inDays >= 2) return '${gap.inDays} days ago';
    if (gap.inDays == 1) return 'yesterday';
    if (gap.inHours >= 1) return '${gap.inHours} h ago';
    return 'a little while ago';
  }
}
