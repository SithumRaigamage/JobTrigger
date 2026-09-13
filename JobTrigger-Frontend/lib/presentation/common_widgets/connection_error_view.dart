import 'package:flutter/material.dart';

/// Ported from `Shared/Components/ConnectionErrorView.swift`. Generic over
/// [message] so it covers both `NetworkFailure` cases from
/// `docs/api-reference.md` — unreachable backend and unreachable Jenkins
/// server — rather than hardcoding "backend server" like the original.
class ConnectionErrorView extends StatelessWidget {
  const ConnectionErrorView({
    super.key,
    required this.onRetry,
    this.message =
        'Unable to reach the server.\nPlease check your connection and try again.',
  });

  final VoidCallback onRetry;
  final String message;

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
        ],
      ),
    );
  }
}
