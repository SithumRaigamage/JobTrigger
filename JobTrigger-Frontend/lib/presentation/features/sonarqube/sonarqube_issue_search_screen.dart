import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/sonarqube/sonarqube_issue.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/main_scaffold.dart';
import 'sonarqube_issue_search_notifier.dart';
import 'sonarqube_issue_widgets.dart';

/// `US-SQ-ISSUES-03`: find a known problem wherever it is, by rule, tag,
/// file path or issue key. SonarQube has no free-text issue search, so each
/// choice is one of the filters the server really has (see
/// [SonarQubeIssueSearchField]).
class SonarQubeIssueSearchScreen extends ConsumerStatefulWidget {
  const SonarQubeIssueSearchScreen({super.key});

  @override
  ConsumerState<SonarQubeIssueSearchScreen> createState() =>
      _SonarQubeIssueSearchScreenState();
}

class _SonarQubeIssueSearchScreenState
    extends ConsumerState<SonarQubeIssueSearchScreen> {
  final _controller = TextEditingController();
  SonarQubeIssueSearchField _field = SonarQubeIssueSearchField.rule;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => ref
      .read(sonarQubeIssueSearchNotifierProvider.notifier)
      .search(_controller.text, _field);

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(sonarQubeIssueSearchNotifierProvider);
    final notifier = ref.read(sonarQubeIssueSearchNotifierProvider.notifier);
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
                            'Across every project',
                            style: textTheme.bodySmall?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                          Semantics(
                            header: true,
                            child: Text(
                              'Search issues',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final field in SonarQubeIssueSearchField.values)
                          ChoiceChip(
                            label: Text(field.label),
                            selected: _field == field,
                            onSelected: (_) => setState(() => _field = field),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      autocorrect: false,
                      enableSuggestions: false,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'e.g. ${_field.hint}',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          tooltip: 'Search',
                          icon: const Icon(Icons.arrow_forward_rounded),
                          onPressed: _submit,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: searchAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: _submit,
                    ),
                  ),
                  data: (loaded) => ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      16 + glassNavBarClearance(context),
                    ),
                    children: [
                      SonarQubeIssueFilterChips(
                        filter: loaded.filter,
                        onChanged: notifier.setFilter,
                      ),
                      const SizedBox(height: 12),
                      if (!loaded.hasSearched)
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Text(
                            'SonarQube has no free-text issue search, so '
                            'choose what to look for: a rule, a tag, a file '
                            'path or an issue key.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                        )
                      else if (loaded.issues.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Text(
                            'No issues match',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                        )
                      else ...[
                        Text(
                          loaded.issues.length == loaded.total
                              ? '${loaded.total} open '
                                    '${loaded.total == 1 ? 'issue' : 'issues'}'
                              : '${loaded.issues.length} of '
                                    '${loaded.total} open issues',
                          style: textTheme.bodySmall?.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final issue in loaded.issues)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SonarQubeCrossProjectIssueCard(issue: issue),
                          ),
                        if (loaded.hasMore)
                          OutlinedButton(
                            onPressed: loaded.loadingMore
                                ? null
                                : notifier.loadMore,
                            child: Text(
                              loaded.loadingMore ? 'Loading…' : 'Load more',
                            ),
                          ),
                      ],
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
