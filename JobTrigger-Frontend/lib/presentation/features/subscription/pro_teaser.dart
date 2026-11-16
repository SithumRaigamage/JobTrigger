import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import 'plan_gate.dart';

/// P20-25: what a Free user sees in place of a Pro-only card or screen
/// body: one line of what it is, a "Pro" mark and a button to the paywall
/// with [reason]. Shown only when `PlanGate` blocks the feature, so with
/// billing off it never appears.
class ProTeaser extends StatelessWidget {
  const ProTeaser({
    super.key,
    required this.reason,
    required this.title,
    required this.message,
  });

  /// The paywall reason (`insights`, ...).
  final String reason;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return GlassSurface.card(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: textTheme.titleSmall)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: t.running.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Pro',
                  style: textTheme.labelSmall?.copyWith(
                    color: t.running.foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () => openPaywall(context, reason),
              child: const Text('See Pro'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A whole screen's worth of [ProTeaser], with a back button, for a Pro-only
/// screen a Free user opened (Nodes, Queue).
class ProTeaserScreen extends StatelessWidget {
  const ProTeaserScreen({
    super.key,
    required this.reason,
    required this.title,
    required this.message,
  });

  final String reason;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.topCenter,
              child: ProTeaser(reason: reason, title: title, message: message),
            ),
          ),
        ),
      ),
    );
  }
}
