import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/sonarqube/sonarqube_issue.dart';
import '../../common_widgets/glass_surface.dart';

/// The type and severity chips shared by the cross-project issue lists
/// (`US-SQ-ISSUES-01` and `US-SQ-ISSUES-03`).
class SonarQubeIssueFilterChips extends StatelessWidget {
  const SonarQubeIssueFilterChips({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final SonarQubeIssueFilter filter;
  final ValueChanged<SonarQubeIssueFilter> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final type in sonarQubeIssueTypes)
            FilterChip(
              label: Text(sonarQubeIssueTypeLabel(type)),
              selected: filter.types.contains(type),
              onSelected: (_) => onChanged(filter.toggleType(type)),
            ),
        ],
      ),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final severity in sonarQubeIssueSeverities)
            FilterChip(
              label: Text(sonarQubeSeverityLabel(severity)),
              selected: filter.severities.contains(severity),
              onSelected: (_) => onChanged(filter.toggleSeverity(severity)),
            ),
        ],
      ),
    ],
  );
}

class SonarQubeCrossProjectIssueCard extends StatelessWidget {
  const SonarQubeCrossProjectIssueCard({super.key, required this.issue});

  final SonarQubeIssue issue;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final project = issue.projectLabel;
    final where = [?project, ?issue.location].join(' · ');
    return GlassSurface.card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            issue.message,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  where,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(color: t.textMuted),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${sonarQubeIssueTypeLabel(issue.type)} · '
                '${sonarQubeSeverityLabel(issue.severity)}',
                style: textTheme.bodySmall?.copyWith(color: t.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
