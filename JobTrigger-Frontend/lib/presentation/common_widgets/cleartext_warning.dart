import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'inline_alert.dart';

/// AUD-14 / AUD-52: shown under a server URL field when it's `http://`.
/// [secretDescription] names what travels in plain text ("your username and
/// password or token", "your token").
class CleartextWarning extends StatelessWidget {
  const CleartextWarning({super.key, required this.secretDescription});

  final String secretDescription;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InlineAlert(
        tone: StatusTone.unstable,
        icon: Icons.lock_open_rounded,
        message:
            'Not encrypted: $secretDescription sent in plain text with '
            'every request. Use https:// unless this server is only '
            'reachable on a network you trust.',
      ),
    );
  }
}
