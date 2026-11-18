import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../domain/jenkins/relative_time.dart';
import 'inline_alert.dart';

part 'data_freshness.g.dart';

/// PI-05 / IMP-38: when a screen last showed live data, or when it fell back
/// to a saved copy. A record gives value equality so Riverpod only rebuilds
/// watchers when something actually changes.
typedef FreshnessState = ({DateTime? savedAt, bool offline});

/// Per-screen freshness, keyed by a stable string so independent screens
/// don't overwrite each other ("Updated 2m ago" must mean that screen).
@riverpod
class DataFreshnessNotifier extends _$DataFreshnessNotifier {
  @override
  FreshnessState build(String key) => (savedAt: null, offline: false);

  void markLoaded([DateTime? at]) =>
      state = (savedAt: at ?? DateTime.now(), offline: false);

  void markOffline(DateTime savedAt) =>
      state = (savedAt: savedAt, offline: true);
}

const homeFreshnessKey = 'home';
String jobDetailFreshnessKey(String jobUrl) => 'job-detail:$jobUrl';
String jobHistoryFreshnessKey(String jobUrl) => 'job-history:$jobUrl';
const gitHubReposFreshnessKey = 'github-repos';
String gitHubRunsFreshnessKey(String owner, String repo, int workflowId) =>
    'github-runs:$owner/$repo/$workflowId';
const sonarqubeProjectsFreshnessKey = 'sonarqube-projects';
String sonarqubeIssuesFreshnessKey(String projectKey) =>
    'sonarqube-issues:$projectKey';

/// Called by a screen's notifier once a fetch resolves. Kept as one helper
/// so every tool records the same shape of state.
void recordFreshness(
  Ref ref,
  String key, {
  DateTime? savedAt,
  bool offline = false,
}) {
  final notifier = ref.read(dataFreshnessNotifierProvider(key).notifier);
  if (offline && savedAt != null) {
    notifier.markOffline(savedAt);
  } else {
    notifier.markLoaded(savedAt);
  }
}

/// Which wording a screen uses. Jenkins' offline copy names the time the
/// data was saved; SonarQube's long-standing banner says "Saved 2h ago ·
/// can't reach the server". Both keep their existing copy (PI-05).
enum FreshnessStyle { jenkins, sonarqube }

/// A small "Updated 2m ago" / "Offline — showing data from HH:MM" note.
///
/// Pass [freshnessKey] to watch the shared notifier, or pass both [savedAt]
/// and [offline] for a caller that already owns the state (the existing
/// banners in Home and SonarQube). [showOffline: false] leaves the offline
/// message to a more specific banner on the same screen.
class DataFreshnessBanner extends ConsumerWidget {
  const DataFreshnessBanner({
    super.key,
    this.freshnessKey,
    this.savedAt,
    this.offline,
    this.style = FreshnessStyle.jenkins,
    this.showOffline = true,
    this.padding = const EdgeInsets.only(top: 12),
  }) : assert(
         freshnessKey != null || (savedAt != null && offline != null),
         'Pass either freshnessKey or both savedAt and offline',
       );

  final String? freshnessKey;
  final DateTime? savedAt;
  final bool? offline;
  final FreshnessStyle style;
  final bool showOffline;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = freshnessKey == null
        ? null
        : ref.watch(dataFreshnessNotifierProvider(freshnessKey!));
    final effectiveSavedAt = savedAt ?? watched?.savedAt;
    final effectiveOffline = offline ?? watched?.offline ?? false;
    if (effectiveSavedAt == null) return const SizedBox.shrink();
    if (effectiveOffline && !showOffline) return const SizedBox.shrink();

    final text = switch (style) {
      FreshnessStyle.jenkins =>
        effectiveOffline
            ? 'Offline — showing data from ${clockTime(effectiveSavedAt.toLocal())}. '
                  "Builds can't be started or changed until you're back online."
            : 'Updated ${relativeTime(effectiveSavedAt)}',
      FreshnessStyle.sonarqube =>
        effectiveOffline
            ? 'Saved ${relativeTime(effectiveSavedAt)} · can\'t reach the server'
            : 'Updated ${relativeTime(effectiveSavedAt)}',
    };
    final icon = effectiveOffline
        ? Icons.cloud_off_rounded
        : Icons.update_rounded;

    return switch (style) {
      FreshnessStyle.jenkins => Padding(
        padding: padding,
        child: InlineAlert(icon: icon, tone: StatusTone.neutral, message: text),
      ),
      FreshnessStyle.sonarqube => Semantics(
        label: text,
        excludeSemantics: true,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTokens.of(context).neutral.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppTokens.of(context).neutral.foreground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTokens.of(context).neutral.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    };
  }
}
