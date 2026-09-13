import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveCenter(
              maxWidth: 900,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  // Centered to match the centered card grid below --
                  // previously left-aligned while the cards (a Wrap)
                  // centered as a group, which read as misaligned.
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 16.0;
                      final columns = responsiveColumnCount(
                        constraints.maxWidth,
                        // Wider than the grid utility's own 180 default --
                        // _ToolCard's fixed-height content (icon +
                        // up-to-2-line label) overflows its cell below
                        // ~180px of width at the 0.95 aspect ratio used
                        // below, so this keeps a safety margin rather than
                        // tuning it to the exact pixel.
                        targetTileWidth: 220,
                      );
                      final cardWidth =
                          (constraints.maxWidth - (columns - 1) * spacing) /
                          columns;
                      // Wrap (not GridView) so a trailing partial row --
                      // e.g. 5 tools at 4 columns leaving 1 alone -- centers
                      // as a group instead of sitting flush left with a
                      // large empty gap beside it.
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final tool in CiTool.values)
                            SizedBox(
                              width: cardWidth,
                              height: cardWidth / 0.95,
                              child: _ToolCard(tool: tool),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});

  final CiTool tool;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: tool.isAvailable ? 1.0 : 0.6,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: tool.isAvailable ? () => context.go(AppRoutes.home) : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: tool.isAvailable
                    ? tool.accentColor.withValues(alpha: 0.25)
                    : Colors.grey.withValues(alpha: 0.1),
                width: 1.5,
              ),
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
                          size: 28,
                          color: tool.accentColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tool.displayName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: tool.isAvailable
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
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
