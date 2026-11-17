import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../data/credentials/credentials_notifier.dart';
import '../../../data/credentials/github_credentials_notifier.dart';
import '../../../data/credentials/sonarqube_credentials_notifier.dart';
import '../../../data/demo/demo_mode_notifier.dart';
import '../../../domain/onboarding/first_run_steps.dart';
import '../notifications/build_watch_notifier.dart';
import '../sonarqube/sonarqube_watch_notifier.dart';
import 'first_run_notifier.dart';

const firstRunChecklistKey = Key('first_run_checklist');

/// PI-08 / IMP-74: a dismissible "get started" card shown on each tool's
/// Home screen until the user connects a tool, triggers a build, and turns
/// on alerts. Hidden in demo mode, once dismissed, and once all three steps
/// are done.
class FirstRunChecklistCard extends ConsumerWidget {
  const FirstRunChecklistCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nothing to set up in demo mode: its sample data is already connected.
    if (ref.watch(demoModeNotifierProvider)) return const SizedBox.shrink();

    final local = ref.watch(firstRunNotifierProvider);
    if (local.dismissed) return const SizedBox.shrink();

    final jenkins = ref.watch(credentialsNotifierProvider);
    final gitHub = ref.watch(gitHubCredentialsNotifierProvider);
    final sonarQube = ref.watch(sonarQubeCredentialsNotifierProvider);
    // Wait until every list has loaded: a flash of "not connected" while
    // the saved credentials are still arriving would be wrong.
    if (!jenkins.hasValue || !gitHub.hasValue || !sonarQube.hasValue) {
      return const SizedBox.shrink();
    }

    final steps = FirstRunSteps(
      connected:
          jenkins.value!.isNotEmpty ||
          gitHub.value!.isNotEmpty ||
          sonarQube.value!.isNotEmpty,
      triggered: local.triggered,
      alerts:
          ref.watch(buildWatchNotifierProvider).isNotEmpty ||
          ref.watch(sonarQubeWatchNotifierProvider).isNotEmpty,
    );
    if (steps.allDone) return const SizedBox.shrink();

    return Padding(
      key: firstRunChecklistKey,
      padding: const EdgeInsets.only(top: 12),
      child: _Card(steps: steps),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.steps});

  final FirstRunSteps steps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Get started', style: textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    ref.read(firstRunNotifierProvider.notifier).dismiss(),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${steps.doneCount} of 3 done — three steps to your first build.',
              style: textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          _Step(
            done: steps.connected,
            title: 'Connect a server',
            hint: 'Add a Jenkins, GitHub or SonarQube account in Settings.',
          ),
          _Step(
            done: steps.triggered,
            title: 'Trigger a build',
            hint: 'Start one from any job or workflow.',
          ),
          _Step(
            done: steps.alerts,
            title: 'Turn on alerts',
            hint: 'Tap the bell on a job to hear when builds finish.',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.done,
    required this.title,
    required this.hint,
    this.last = false,
  });

  final bool done;
  final String title;
  final String hint;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 20,
            color: done ? t.success.dot : t.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? t.textMuted : null,
                  ),
                ),
                Text(hint, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
