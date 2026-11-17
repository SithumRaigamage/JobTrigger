import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_routes.dart';

/// Ported from `Shared/Components/ConnectionErrorView.swift`. Generic over
/// [message] so it covers both `NetworkFailure` cases from
/// `docs/api-reference.md` — unreachable backend and unreachable Jenkins
/// server — rather than hardcoded "backend server" like the original.
///
/// PI-03: every connection error offers a "Why can't I reach it?" action that
/// opens the help screen. Callers can pass [onHelp] to override it (tests, or
/// a screen with a more specific destination).
class ConnectionErrorView extends StatelessWidget {
  const ConnectionErrorView({
    super.key,
    required this.onRetry,
    this.message =
        'Unable to reach the server.\nPlease check your connection and try again.',
    this.onHelp,
  });

  final VoidCallback onRetry;
  final String message;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Defensive: [message] should always be a short, friendly string
      // (see `describeError`), but an unmapped error's raw `toString()`
      // can be arbitrarily long (a full stack trace) -- scroll rather than
      // overflow if that ever happens instead of throwing a render error.
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'Connection Failed',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Retry Connection'),
          ),
          TextButton.icon(
            onPressed: onHelp ?? () => context.push(AppRoutes.connectionHelp),
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            icon: const Icon(Icons.help_outline_rounded),
            label: const Text("Why can't I reach it?"),
          ),
        ],
      ),
    );
  }
}
