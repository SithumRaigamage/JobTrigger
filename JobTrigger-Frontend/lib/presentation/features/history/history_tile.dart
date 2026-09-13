import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/jenkins/jenkins_build.dart';

/// Shared between `GlobalHistoryScreen` and the per-job history view
/// (P5-16) — one row per build.
class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.jenkinsBuild,
    this.jobName,
    this.onTap,
  });

  final JenkinsBuild jenkinsBuild;

  /// Shown ahead of the build number for the global (cross-job) view;
  /// omitted for a per-job list where it'd be redundant.
  final String? jobName;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = jobName == null
        ? '#${jenkinsBuild.number}'
        : '$jobName #${jenkinsBuild.number}';

    return ListTile(
      leading: Icon(
        Icons.circle,
        size: 12,
        color: AppColors.forBuildResult(jenkinsBuild.result),
      ),
      title: Text(title),
      subtitle: Text(_formatTimestamp(jenkinsBuild.timestamp)),
      trailing: Text(
        jenkinsBuild.building ? 'Building' : (jenkinsBuild.result ?? '—'),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.forBuildResult(jenkinsBuild.result),
        ),
      ),
      onTap: onTap,
    );
  }

  static String _formatTimestamp(double epochMillis) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochMillis.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }
}
