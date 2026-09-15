import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_routes.dart';

/// GitHub-side equivalent of [NoActiveServerView] — shown instead of a
/// GitHub-dependent screen's real content when no GitHub credential is
/// configured yet. `gitHubClientProvider` throws a raw `StateError` if
/// built with no active credential (mirrors `jenkinsClientProvider`'s own
/// doc comment/contract); this widget is the gate screens use before ever
/// watching a GitHub-backed provider.
class NoActiveGitHubCredentialView extends StatelessWidget {
  const NoActiveGitHubCredentialView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.vpn_key_outlined,
            size: 60,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 20),
          Text(
            'No GitHub Credential',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a GitHub personal access token in Settings to see your '
            'repositories.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.settings),
            icon: const Icon(Icons.add),
            label: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }
}
