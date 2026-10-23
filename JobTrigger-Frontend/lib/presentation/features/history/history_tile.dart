import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/status_pill.dart';
import '../../common_widgets/status_tile.dart';

/// Shared between `GlobalHistoryScreen` and the per-job history view
/// (P5-16) — one row per build, laid out to the P14 design
/// (`UI-UX/screens/08-global-history`): a status tile, "job #n", the
/// result and duration in the status colour, and when it started.
class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.jenkinsBuild,
    this.jobName,
    this.onTap,
    this.onReplay,
    this.grouped = false,
  });

  final JenkinsBuild jenkinsBuild;

  /// Shown ahead of the build number for the global (cross-job) view;
  /// omitted for a per-job list where it'd be redundant.
  final String? jobName;

  final VoidCallback? onTap;

  /// US-PIPE-08: shows a trailing "Replay" action when set. Only
  /// `JobHistoryScreen` wires this up — reconciling against a job's
  /// *current* parameter definitions needs that job in scope, which the
  /// global cross-job history view doesn't have.
  final VoidCallback? onReplay;

  /// A row inside a grouped card under a day heading: no card of its own,
  /// and only the time of day, since the heading gives the date.
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final build = jenkinsBuild;
    final tone = build.building
        ? StatusTone.running
        : AppColors.toneForBuildResult(build.result);
    final started = fromJenkinsTimestamp(build.timestamp);
    final duration = build.duration;
    final detail = [
      StatusPill.labelForBuildResult(build.building ? null : build.result),
      if (build.building)
        'started ${relativeTime(started)}'
      else if (duration != null && duration > 0)
        formatBuildDuration(duration),
    ].join(' · ');
    final mono = AppTypography.mono(textTheme.bodySmall).copyWith(fontSize: 12);

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          StatusTile(tone: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      if (jobName != null) TextSpan(text: '$jobName '),
                      TextSpan(
                        text: '#${build.number}',
                        style: AppTypography.mono(null).copyWith(
                          color: jobName == null ? t.text : t.textMuted,
                          fontWeight: jobName == null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: t.status(tone).foreground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(grouped ? clockTime(started) : _dateTime(started), style: mono),
          if (onReplay != null)
            IconButton(
              icon: const Icon(Icons.replay_rounded, size: 20),
              tooltip: 'Replay with same parameters',
              onPressed: onReplay,
            ),
        ],
      ),
    );

    if (grouped) {
      return Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, child: row),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassSurface.card(onTap: onTap, child: row),
    );
  }

  /// `Today 10:41`, `Yesterday 17:05`, `Mon 19 Oct 14:19`.
  static String _dateTime(DateTime time) =>
      '${dayLabel(time)} ${clockTime(time)}';
}
