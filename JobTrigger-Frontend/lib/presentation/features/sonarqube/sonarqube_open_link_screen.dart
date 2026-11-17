import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/error_message.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../navigation/app_routes.dart';

part 'sonarqube_open_link_screen.g.dart';

/// The project a `jobtrigger://app/sonarqube/project?key=` link names
/// (`US-SQ-LINK-02`), looked up on the active credential.
@riverpod
Future<SonarQubeProject> sonarQubeLinkedProject(Ref ref, String key) async {
  final result = await ref
      .watch(sonarQubeRepositoryProvider)
      .fetchProjectByKey(key);
  return result.fold<SonarQubeProject>(
    (project) => project,
    (Object failure) => throw failure,
  );
}

/// Opens the linked project, or says what is missing. Never a blank screen
/// and never a choice of server: the link carries a key only.
class SonarQubeOpenLinkScreen extends ConsumerWidget {
  const SonarQubeOpenLinkScreen({required this.projectKey, super.key});

  final String projectKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credential = ref.watch(activeSonarQubeCredentialNotifierProvider);
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    Widget message(
      String title,
      String body, {
      List<Widget> actions = const [],
    }) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: 16),
            ...actions,
          ],
        ),
      ),
    );

    final home = TextButton(
      onPressed: () => context.go(AppRoutes.home),
      child: const Text('Go to Home'),
    );

    Widget body;
    if (credential == null) {
      body = message(
        'No SonarQube credential',
        'This link opens a SonarQube project, but no SonarQube server is set '
            'up on this device. Add one in Settings, then open the link again.',
        actions: [home],
      );
    } else {
      final project = ref.watch(sonarQubeLinkedProjectProvider(projectKey));
      body = project.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => message(
          "Couldn't open the project",
          describeError(error),
          actions: [
            TextButton(
              onPressed: () =>
                  ref.invalidate(sonarQubeLinkedProjectProvider(projectKey)),
              child: const Text('Retry'),
            ),
            home,
          ],
        ),
        data: (found) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.pushReplacement(AppRoutes.sonarqubeProject, extra: found);
            }
          });
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    return Scaffold(body: SafeArea(child: body));
  }
}
