import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../domain/jenkins/relative_time.dart';
import '../../../domain/sonarqube/sonarqube_issue.dart';
import '../../../domain/sonarqube/sonarqube_links.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/external_link.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/section_label.dart';
import '../../common_widgets/status_pill.dart';
import '../../navigation/main_scaffold.dart';
import 'sonarqube_issue_context.dart';

/// One issue in full (`US-SQ-QUALITY-06`): what is wrong, where, which rule
/// raised it, how long it should take to fix, who wrote the code and when it
/// was raised, and the code around it. Everything the list already knows is
/// shown at once; the rule's name and the code arrive a moment later.
class SonarQubeIssueScreen extends ConsumerWidget {
  const SonarQubeIssueScreen({
    required this.project,
    required this.issue,
    super.key,
  });

  final SonarQubeProject project;
  final SonarQubeIssue issue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credential = ref.watch(activeSonarQubeCredentialNotifierProvider);
    final contextAsync = ref.watch(sonarQubeIssueContextProvider(issue));
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final created = issue.creationDate;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          child: ListView(
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
                        sonarQubeIssueUri(
                          credential.baseUrl,
                          project.key,
                          issue.key,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                project.name,
                style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StatusPill(
                    label: sonarQubeIssueTypeLabel(issue.type),
                    tone: StatusTone.neutral,
                  ),
                  StatusPill(
                    label: sonarQubeSeverityLabel(issue.severity),
                    tone: switch (issue.severity) {
                      'BLOCKER' || 'CRITICAL' => StatusTone.failure,
                      'MAJOR' => StatusTone.unstable,
                      'MINOR' => StatusTone.paused,
                      _ => StatusTone.neutral,
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text(issue.message, style: textTheme.titleLarge),
              ),
              const SizedBox(height: 20),
              GlassSurface.card(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (issue.rule != null)
                      _Fact(
                        label: 'Rule',
                        child: _RuleText(
                          rule: issue.rule!,
                          name: contextAsync.value?.ruleName,
                        ),
                      ),
                    if (issue.location != null)
                      _Fact(
                        label: 'Where',
                        child: Text(
                          issue.location!,
                          style: AppTypography.mono(
                            textTheme.bodyMedium,
                          ).copyWith(fontSize: 13),
                        ),
                      ),
                    if (issue.effort != null)
                      _Fact(
                        label: 'Effort',
                        child: Text('${issue.effort} to fix'),
                      ),
                    if (issue.status != null)
                      _Fact(
                        label: 'Status',
                        child: Text(_humanStatus(issue.status!)),
                      ),
                    if (issue.author != null)
                      _Fact(label: 'Author', child: Text(issue.author!)),
                    if (created != null)
                      _Fact(
                        label: 'Raised',
                        child: Text(relativeTime(created)),
                      ),
                    if (issue.tags.isNotEmpty)
                      _Fact(
                        label: 'Tags',
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final tag in issue.tags)
                              Chip(
                                label: Text(tag),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (issue.component != null && issue.line != null) ...[
                const SizedBox(height: 24),
                const SectionLabel('Code'),
                const SizedBox(height: 8),
                contextAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => ConnectionErrorView(
                    message: describeError(error),
                    onRetry: () =>
                        ref.invalidate(sonarQubeIssueContextProvider(issue)),
                  ),
                  data: (context) => context.snippet.isEmpty
                      ? Text(
                          "The code isn't available.",
                          style: textTheme.bodyMedium?.copyWith(
                            color: t.textMuted,
                          ),
                        )
                      : _Code(lines: context.snippet, issueLine: issue.line!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _humanStatus(String status) {
  final words = status.replaceAll('_', ' ').toLowerCase();
  return words.isEmpty ? status : words[0].toUpperCase() + words.substring(1);
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: t.textMuted),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// The rule's key, with its name under it once that has loaded.
class _RuleText extends StatelessWidget {
  const _RuleText({required this.rule, required this.name});

  final String rule;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rule,
          style: AppTypography.mono(
            textTheme.bodyMedium,
          ).copyWith(fontSize: 13),
        ),
        if (name != null)
          Text(
            name!,
            style: textTheme.bodySmall?.copyWith(
              color: AppTokens.of(context).textMuted,
            ),
          ),
      ],
    );
  }
}

/// The lines around the issue, numbered, with the issue's own line marked.
/// Scrolls sideways: code lines are long.
class _Code extends StatelessWidget {
  const _Code({required this.lines, required this.issueLine});

  final List<SonarQubeSourceLine> lines;
  final int issueLine;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final mono = AppTypography.mono(
      Theme.of(context).textTheme.bodySmall,
    ).copyWith(fontSize: 12.5, height: 1.5);
    return GlassSurface.card(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final line in lines)
                Semantics(
                  label:
                      'Line ${line.number}'
                      '${line.number == issueLine ? ', the issue' : ''}: '
                      '${line.code}',
                  excludeSemantics: true,
                  child: Container(
                    color: line.number == issueLine
                        ? t.failure.background
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 1,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${line.number}',
                            textAlign: TextAlign.right,
                            style: mono.copyWith(color: t.textMuted),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(line.code.isEmpty ? ' ' : line.code, style: mono),
                      ],
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
