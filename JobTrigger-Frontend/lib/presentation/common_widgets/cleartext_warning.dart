import 'package:flutter/material.dart';

/// AUD-14 / AUD-52: shown under a server URL field when it's `http://`.
/// [secretDescription] names what travels in plain text ("your username and
/// password or token", "your token").
class CleartextWarning extends StatelessWidget {
  const CleartextWarning({super.key, required this.secretDescription});

  final String secretDescription;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_open, size: 18, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Not encrypted: $secretDescription sent in plain text with '
              'every request. Use https:// unless this server is only '
              'reachable on a network you trust.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
