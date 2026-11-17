import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// A short list of rows in one card with hairlines between them — the
/// redesign's settings-style group (`UI-UX/screens/09-settings`,
/// `10-profile`). For long or unbounded lists use a `DecoratedSliver` so
/// the rows are built lazily.
class GroupedCard extends StatelessWidget {
  const GroupedCard({super.key, required this.children, this.padding});

  final List<Widget> children;

  /// Padding inside the card; rows usually carry their own.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.cardBorder),
      ),
      // Rows' ink stays inside the rounded corners.
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const Divider(),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// A section heading over a [GroupedCard], with an optional inline action
/// such as "Add" on the right.
class GroupHeader extends StatelessWidget {
  const GroupHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                semanticsLabel: title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: t.textMuted,
                  letterSpacing: 0.72,
                ),
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
