import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../data/datasources/sonarqube_client_factory.dart';
import '../../../domain/sonarqube/sonarqube_branch_ref.dart';
import 'sonarqube_quality_notifiers.dart';

/// `US-SQ-QUALITY-10`: switches the whole page to another analysed branch or
/// pull request. Hidden when only the main branch exists (Community Build),
/// so it is never a control that does nothing.
class SonarQubeBranchPicker extends ConsumerWidget {
  const SonarQubeBranchPicker({required this.projectKey, super.key});

  final String projectKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choices = ref.watch(sonarQubeProjectRefsProvider(projectKey));
    final selections = ref.watch(sonarQubeBranchSelectionsNotifierProvider);
    final selected = selections[projectKey] ?? const SonarQubeBranchRef.main();
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    return choices.maybeWhen(
      data: (choices) => !choices.hasChoice
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<SonarQubeBranchRef>(
                tooltip: 'Branch or pull request',
                onSelected: (choice) => ref
                    .read(sonarQubeBranchSelectionsNotifierProvider.notifier)
                    .set(projectKey, choice),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: SonarQubeBranchRef.main(),
                    child: Text('Main branch'),
                  ),
                  for (final choice in choices.refs)
                    PopupMenuItem(value: choice, child: Text(choice.label)),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.call_split_rounded,
                        size: 16,
                        color: t.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        selected.label,
                        style: textTheme.bodySmall?.copyWith(
                          color: t.textMuted,
                        ),
                      ),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 18,
                        color: t.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
