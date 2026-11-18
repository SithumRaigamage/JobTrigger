import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/error/result.dart';
import '../../../data/cache/server_safety_store.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/safety/server_safety.dart';
import '../../../domain/sonarqube/sonarqube_issue_actions.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/sonarqube/sonarqube_hotspot.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/main_scaffold.dart';
import '../../common_widgets/tool_server_credential_header.dart';
import 'sonarqube_change_dialogs.dart';
import 'sonarqube_hotspots_notifier.dart';

/// `US-SQ-HOTSPOT-01`: a project's security hotspots, the ones still to
/// review or the reviewed ones, each expandable to its rule and code.
/// Reviewing a hotspot is a change (`US-SQ-WRITE-04`) and asks first.
class SonarQubeHotspotsScreen extends ConsumerStatefulWidget {
  const SonarQubeHotspotsScreen({required this.project, super.key});

  final SonarQubeProject project;

  @override
  ConsumerState<SonarQubeHotspotsScreen> createState() =>
      _SonarQubeHotspotsScreenState();
}

class _SonarQubeHotspotsScreenState
    extends ConsumerState<SonarQubeHotspotsScreen> {
  bool _reviewed = false;

  @override
  Widget build(BuildContext context) {
    final credential = ref.watch(activeSonarQubeCredentialNotifierProvider);
    final provider = sonarQubeHotspotsNotifierProvider(widget.project.key);
    final hotspotsAsync = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
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
                              'Security hotspots',
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
                    ChoiceChip(
                      label: const Text('To review'),
                      selected: !_reviewed,
                      onSelected: (_) {
                        setState(() => _reviewed = false);
                        notifier.setReviewed(reviewed: false);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Reviewed'),
                      selected: _reviewed,
                      onSelected: (_) {
                        setState(() => _reviewed = true);
                        notifier.setReviewed(reviewed: true);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: hotspotsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () => notifier.setReviewed(reviewed: _reviewed),
                    ),
                  ),
                  data: (page) => RefreshIndicator(
                    onRefresh: () => notifier.setReviewed(reviewed: _reviewed),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        16 + glassNavBarClearance(context),
                      ),
                      children: [
                        if (page.hotspots.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(
                              _reviewed
                                  ? 'No reviewed hotspots yet'
                                  : 'Nothing to review',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: t.textMuted,
                              ),
                            ),
                          )
                        else ...[
                          Text(
                            page.hotspots.length == page.total
                                ? '${page.total} '
                                      '${page.total == 1 ? 'hotspot' : 'hotspots'}'
                                : '${page.hotspots.length} of ${page.total}',
                            style: textTheme.bodySmall?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final hotspot in page.hotspots)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HotspotRow(hotspot: hotspot),
                            ),
                          if (page.hasMore)
                            OutlinedButton(
                              onPressed: page.loadingMore
                                  ? null
                                  : () =>
                                        notifier.loadMore(reviewed: _reviewed),
                              child: Text(
                                page.loadingMore ? 'Loading…' : 'Load more',
                              ),
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

class _HotspotRow extends ConsumerWidget {
  const _HotspotRow({required this.hotspot});

  final SonarQubeHotspot hotspot;

  /// PI-01/IMP-25: reviewing is a write action — no-op on a read-only
  /// credential, even if a stale button survived a rebuild.
  bool _readOnly(WidgetRef ref) {
    final safety = ref.read(serverSafetyNotifierProvider);
    final active = ref.read(activeSonarQubeCredentialNotifierProvider);
    return active != null && safety.isReadOnly(SafetyTool.sonarqube, active.id);
  }

  Future<void> _review(BuildContext context, WidgetRef ref) async {
    if (_readOnly(ref)) return;
    final repo = ref.read(sonarQubeRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final review = await pickSonarQubeChoice<SonarQubeHotspotReview>(
      context,
      title: 'Review this hotspot',
      choices: [
        for (final r in SonarQubeHotspotReview.values)
          // Offer only decisions that differ from where it already is.
          if (!(r == SonarQubeHotspotReview.toReview && !hotspot.isReviewed))
            (r.label, r),
      ],
    );
    if (review == null || !context.mounted) return;
    final comment = await askSonarQubeText(
      context,
      title: 'Comment (optional)',
      label: 'Visible to everyone on this project',
      confirmLabel: 'Next',
      maxLines: 3,
    );
    if (!context.mounted) return;
    final yes = await confirmSonarQubeChange(
      context,
      title: 'Mark as ${review.label.toLowerCase()}?',
      body: 'This changes the hotspot on SonarQube for everyone.',
      confirmLabel: 'Confirm',
    );
    if (!yes) return;
    final result = await repo.reviewHotspot(
      hotspot.key,
      review,
      comment: comment,
    );
    switch (result) {
      case Ok():
        // The list is re-read: it changes because the server now says so.
        ref.invalidate(sonarQubeHotspotsNotifierProvider);
        messenger.showSnackBar(const SnackBar(content: Text('Review saved')));
      case Err(:final error):
        messenger.showSnackBar(SnackBar(content: Text(describeError(error))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final safety = ref.watch(serverSafetyNotifierProvider);
    final activeCredential = ref.watch(
      activeSonarQubeCredentialNotifierProvider,
    );
    final readOnly =
        activeCredential != null &&
        safety.isReadOnly(SafetyTool.sonarqube, activeCredential.id);
    final where = [
      if (hotspot.securityCategory != null) hotspot.securityCategory,
      if (hotspot.location != null) hotspot.location,
    ].join(' · ');

    return GlassSurface.card(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(hotspot.message, style: textTheme.bodyMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (where.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  where,
                  style: textTheme.bodySmall?.copyWith(color: t.textMuted),
                ),
              ),
            // The probability is spelled out, never a colour alone.
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                hotspot.probabilityLabel,
                style: textTheme.bodySmall?.copyWith(color: t.textMuted),
              ),
            ),
          ],
        ),
        children: [
          // Batch 7 (US-SQ-WRITE-04): the review decision, confirmed first.
          // PI-01/IMP-25: hidden on a read-only credential.
          if (!readOnly)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Review'),
                onPressed: () => _review(context, ref),
              ),
            ),
          ref
              .watch(sonarQubeHotspotDetailProvider(hotspot.key))
              .when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(),
                ),
                error: (error, _) => Text(
                  describeError(error),
                  style: textTheme.bodySmall?.copyWith(color: t.textMuted),
                ),
                data: (detail) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (detail.ruleName != null)
                      Text(
                        detail.ruleName!,
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (detail.snippet.isEmpty)
                      Text(
                        'No code preview for this hotspot.',
                        style: textTheme.bodySmall?.copyWith(
                          color: t.textMuted,
                        ),
                      )
                    else
                      for (final line in detail.snippet)
                        Text(
                          '${line.number.toString().padLeft(4)}  ${line.code}',
                          style: AppTypography.mono(
                            textTheme.bodySmall,
                          ).copyWith(fontSize: 12),
                        ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
