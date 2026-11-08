import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_routes.dart';

/// SonarQube-side equivalent of `NoActiveGitHubCredentialView`: shown
/// instead of a SonarQube screen's content when no credential is configured
/// yet. `sonarQubeClientProvider` throws a `StateError` with no active
/// credential, so screens gate on this before watching it.
class NoActiveSonarQubeCredentialView extends StatelessWidget {
  const NoActiveSonarQubeCredentialView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.vpn_key_outlined,
            size: 60,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 20),
          Text(
            'No SonarQube Credential',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a SonarQube token and server URL in Settings to see your '
            'projects.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
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
