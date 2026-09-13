import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../common_widgets/gradient_backdrop.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import 'ci_tool.dart';

/// Ported from `Tools/ToolSelection/ToolSelectionView.swift`. Displayed
/// after login, before the main app shell. Static grid — see
/// `docs/state-management.md`'s "Feature: tool_selection" section.
class ToolSelectionScreen extends StatelessWidget {
  const ToolSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: GradientBackdrop(
        color: colorScheme.primary,
        background: colorScheme.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ResponsiveCenter(
                maxWidth: 900,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          color: colorScheme.onPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Choose Your Tool',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a CI/CD platform to get started',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ResponsiveCenter(
                  maxWidth: 900,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const spacing = 16.0;
                            final columns = responsiveColumnCount(
                              constraints.maxWidth,
                              // Wider than the grid utility's own 180
                              // default -- _ToolCard's fixed-height content
                              // (icon + name + tagline) overflows its cell
                              // below ~180px of width at the 1.05 aspect
                              // ratio used below, so this keeps a safety
                              // margin rather than tuning it to the exact
                              // pixel.
                              targetTileWidth: 220,
                            );
                            final cardWidth =
                                (constraints.maxWidth -
                                    (columns - 1) * spacing) /
                                columns;
                            // Wrap (not GridView) so a trailing partial row
                            // -- e.g. 5 tools at 4 columns leaving 1 alone --
                            // centers as a group instead of sitting flush
                            // left with a large empty gap beside it.
                            return Wrap(
                              alignment: WrapAlignment.center,
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                for (final tool in CiTool.values)
                                  SizedBox(
                                    width: cardWidth,
                                    height: cardWidth / 0.85,
                                    child: _ToolCard(tool: tool),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'More integrations rolling out — Jenkins is fully '
                          'supported today.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatefulWidget {
  const _ToolCard({required this.tool});

  final CiTool tool;

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.tool.isAvailable) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: tool.isAvailable ? 1.0 : 0.6,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: tool.isAvailable ? () => context.go(AppRoutes.home) : null,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: tool.isAvailable
                      ? tool.accentColor.withValues(alpha: 0.25)
                      : Colors.grey.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: tool.isAvailable
                    ? [
                        BoxShadow(
                          color: tool.accentColor.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: tool.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            tool.icon,
                            size: 26,
                            color: tool.accentColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          tool.displayName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: tool.isAvailable
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tool.tagline,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        if (tool.isAvailable) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tool.accentColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Recommended',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: tool.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: tool.isAvailable
                        ? Icon(
                            Icons.check_circle,
                            size: 18,
                            color: tool.accentColor,
                          )
                        : const _ComingSoonBadge(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Soon',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
