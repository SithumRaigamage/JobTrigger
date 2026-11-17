import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/credential/token_hygiene.dart';
import '../../common_widgets/external_link.dart';

/// PI-09 / IMP-75: a short in-app guide to creating the token each tool
/// needs, with a button to the tool's own token page.
enum TokenTool { jenkins, github, sonarqube }

Future<void> showTokenWizardSheet(
  BuildContext context, {
  required TokenTool tool,
  String? baseUrl,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => TokenWizardSheet(tool: tool, baseUrl: baseUrl),
);

/// The "How do I get a token?" link each credential sheet shows under its
/// token field, opening [TokenWizardSheet].
class TokenHelpButton extends StatelessWidget {
  const TokenHelpButton({super.key, required this.tool, this.baseUrl});

  final TokenTool tool;
  final String? baseUrl;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
      icon: const Icon(Icons.help_outline_rounded, size: 18),
      label: const Text('How do I get a token?'),
      onPressed: () =>
          showTokenWizardSheet(context, tool: tool, baseUrl: baseUrl),
    ),
  );
}

class TokenWizardSheet extends ConsumerWidget {
  const TokenWizardSheet({super.key, required this.tool, this.baseUrl});

  final TokenTool tool;

  /// The instance URL typed in the edit sheet, when the tool has one.
  final String? baseUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final guide = _guideFor(tool, baseUrl);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(guide.title, style: textTheme.titleLarge),
            const SizedBox(height: 10),
            for (final step in guide.steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(step, style: textTheme.bodyMedium)),
                  ],
                ),
              ),
            if (guide.link != null) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(guide.linkLabel!),
                onPressed: () => openExternalLink(ref, guide.link!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

typedef _TokenGuide = ({
  String title,
  List<String> steps,
  Uri? link,
  String? linkLabel,
});

_TokenGuide _guideFor(TokenTool tool, String? baseUrl) => switch (tool) {
  TokenTool.jenkins => (
    title: 'Create a Jenkins API token',
    steps: [
      'Open your Jenkins profile and choose API tokens.',
      'Add a token, then copy it — Jenkins shows it only once.',
      'Paste it here as the API token.',
    ],
    link: baseUrl == null || baseUrl.trim().isEmpty
        ? null
        : jenkinsTokenPageUrl(baseUrl),
    linkLabel: 'Open Jenkins',
  ),
  TokenTool.github => (
    title: 'Create a GitHub token',
    steps: [
      'Classic token: tick the repo and workflow scopes.',
      'Fine-grained token: give Actions read and write, and Contents read.',
      'Copy the token and paste it here.',
    ],
    link: gitHubTokenPageUrl(),
    linkLabel: 'Open GitHub',
  ),
  TokenTool.sonarqube => (
    title: 'Create a SonarQube token',
    steps: [
      'Open your account security page.',
      'Generate a user token and copy it — it is shown only once.',
      'Paste it here as the user token.',
    ],
    link: sonarQubeTokenPageUrl(
      baseUrl == null || baseUrl.trim().isEmpty
          ? 'https://sonarcloud.io'
          : baseUrl,
    ),
    linkLabel: 'Open SonarQube',
  ),
};
