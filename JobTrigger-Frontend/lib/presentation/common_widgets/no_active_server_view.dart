import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_routes.dart';

/// Shown instead of a Jenkins-dependent screen's real content when no
/// server is configured yet. `jenkinsClient` (`jenkins_client_factory.dart`)
/// throws a raw `StateError` if built with no active server — that error's
/// doc comment says callers are "expected to already gate on a server
/// being configured before reaching that point", but nothing ever did,
/// so a fresh install hit the raw exception (dumped via `describeError`'s
/// `error.toString()` fallback) instead of a clean message. This widget is
/// that gate, used by screens before they ever watch a Jenkins-backed
/// provider.
class NoActiveServerView extends StatelessWidget {
  const NoActiveServerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.dns_outlined,
            size: 60,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 20),
          Text(
            'No Jenkins Server',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a Jenkins server in Settings to see your jobs.',
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
