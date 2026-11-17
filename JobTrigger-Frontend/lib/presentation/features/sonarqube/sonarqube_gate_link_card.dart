import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../../domain/sonarqube/sonarqube_tool_link.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/section_label.dart';
import '../../common_widgets/status_pill.dart';
import '../../navigation/app_routes.dart';
import 'sonarqube_change_dialogs.dart';
import 'sonarqube_gate_style.dart';
import 'sonarqube_projects_notifier.dart';
import 'sonarqube_quality_notifiers.dart';
import 'sonarqube_tool_links_notifier.dart';

/// `US-SQ-XTOOL-01` / `-03`: the quality gate of the SonarQube project linked
/// to a Jenkins job or a GitHub repository, on that tool's own page.
///
/// Additive and self-contained, so the Jenkins and GitHub screens only place
/// it: with no SonarQube credential it draws nothing and those screens look
/// exactly as before. It talks to SonarQube with the SonarQube credential
/// alone; the link is stored on this device; nothing of Jenkins' or GitHub's
/// credentials is read here.
/// Whether this device has chosen a SonarQube credential at all — a local
/// read of the same preference the active-credential notifier writes, with no
/// network. The card checks this before touching any SonarQube provider, so a
/// Jenkins or GitHub page for someone who never set SonarQube up does exactly
/// what it did before (no credential list is fetched on its behalf).
final _sonarQubeConfiguredProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('active_sonarqube_credential_id') != null;
  } on Object {
    return false;
  }
});

class SonarQubeGateLinkCard extends ConsumerWidget {
  const SonarQubeGateLinkCard({
    required this.tool,
    required this.externalId,
    super.key,
  });

  final SonarQubeLinkedTool tool;

  /// The Jenkins job URL, or the GitHub repository's `owner/name`.
  final String externalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(ref.watch(_sonarQubeConfiguredProvider).value ?? false)) {
      return const SizedBox.shrink();
    }
    if (ref.watch(activeSonarQubeCredentialNotifierProvider) == null) {
      return const SizedBox.shrink();
    }
    final links = ref.watch(sonarQubeToolLinksNotifierProvider);
    final link = links[sonarQubeLinkId(tool, externalId)];
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('SonarQube quality gate'),
          const SizedBox(height: 8),
          GlassSurface.card(
            padding: const EdgeInsets.all(14),
            onTap: link == null
                ? () => _pick(context, ref)
                : () => context.push(
                    AppRoutes.sonarqubeProject,
                    extra: SonarQubeProject(
                      key: link.projectKey,
                      name: link.projectName,
                      lastAnalysisDate: null,
                    ),
                  ),
            child: link == null
                ? Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Link a SonarQube project',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  )
                : _Linked(link: link, onUnlink: () => _unlink(context, ref)),
          ),
          if (link == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Stored on this device only.',
                style: textTheme.bodySmall?.copyWith(color: t.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    // The picker lists the projects the SonarQube credential can browse.
    final projects = await ref.read(sonarQubeProjectsNotifierProvider.future);
    if (!context.mounted) return;
    final chosen = await pickSonarQubeChoice<SonarQubeProject>(
      context,
      title: 'Link a SonarQube project',
      choices: [for (final p in projects.projects) (p.name, p)],
    );
    if (chosen == null) return;
    await ref
        .read(sonarQubeToolLinksNotifierProvider.notifier)
        .link(tool, externalId, chosen);
  }

  Future<void> _unlink(BuildContext context, WidgetRef ref) async {
    final yes = await confirmSonarQubeChange(
      context,
      title: 'Unlink this project?',
      body:
          'Only the link on this device is removed. Nothing changes in '
          'SonarQube.',
      confirmLabel: 'Unlink',
    );
    if (!yes) return;
    await ref
        .read(sonarQubeToolLinksNotifierProvider.notifier)
        .unlink(tool, externalId);
  }
}

class _Linked extends ConsumerWidget {
  const _Linked({required this.link, required this.onUnlink});

  final SonarQubeToolLink link;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final gate = ref.watch(
      sonarQubeQualityGateNotifierProvider(link.projectKey),
    );
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(link.projectName, style: textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                gate.when(
                  loading: () => 'Checking the quality gate…',
                  error: (error, _) => describeError(error),
                  data: (g) => 'Tap to open the project',
                ),
                style: textTheme.bodySmall?.copyWith(color: t.textMuted),
              ),
            ],
          ),
        ),
        if (gate.value != null) ...[
          StatusPill(
            label: gateLabel(gate.value!.state),
            tone: gateTone(gate.value!.state),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.link_off_rounded, size: 20),
          tooltip: 'Unlink SonarQube project',
          onPressed: onUnlink,
        ),
      ],
    );
  }
}
