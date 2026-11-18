import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'inline_alert.dart';

/// PI-01/IMP-25: shown wherever a tool's write actions are disabled because
/// the active credential is marked read-only on this device. Browsing and
/// watching keep working — only state-changing actions are blocked.
class ReadOnlyNotice extends StatelessWidget {
  const ReadOnlyNotice({super.key, this.toolLabel = 'server'});

  /// e.g. "server", "GitHub account", "SonarQube account".
  final String toolLabel;

  @override
  Widget build(BuildContext context) => InlineAlert(
    tone: StatusTone.paused,
    icon: Icons.lock_outline_rounded,
    message:
        'This $toolLabel is read-only on this device. Turn that off in '
        'Settings to make changes.',
  );
}
