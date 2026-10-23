import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../common_widgets/responsive_center.dart';
import '../../common_widgets/section_label.dart';
import '../../navigation/app_routes.dart';
import 'active_tool_notifier.dart';
import 'ci_tool.dart';
import 'upcoming_tools.dart';

/// Ported from `Tools/ToolSelection/ToolSelectionView.swift`, laid out to
/// the P14 design (`UI-UX/screens/03-tool-selection`): the available tools
/// as a single-choice list, the not-yet-available ones below them, and a
/// Continue button that commits the choice. Shown after login, and again
/// when switching tool from the profile.
class ToolSelectionScreen extends ConsumerStatefulWidget {
  const ToolSelectionScreen({super.key});

  @override
  ConsumerState<ToolSelectionScreen> createState() =>
      _ToolSelectionScreenState();
}

class _ToolSelectionScreenState extends ConsumerState<ToolSelectionScreen> {
  /// The highlighted choice before Continue — the tool already in use when
  /// switching, Jenkins on first run.
  late CiTool _selected =
      ref.read(activeToolNotifierProvider) ?? CiTool.jenkins;

  void _continue() {
    ref.read(activeToolNotifierProvider.notifier).setActiveTool(_selected);
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final available = CiTool.values.where((tool) => tool.isAvailable);

    // Not PinnedFooterLayout: with every coming-later tool listed the body
    // is several screens tall, and that layout scrolls its footer with the
    // body. Continue stays on screen here; only the list scrolls.
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                child: ResponsiveCenter(
                  maxWidth: 440,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What do you build with?',
                              style: textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You can switch any time from your profile.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: t.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        label: 'CI tool',
                        explicitChildNodes: true,
                        child: Column(
                          children: [
                            for (final tool in available) ...[
                              _ToolOption(
                                tool: tool,
                                selected: tool == _selected,
                                onTap: () => setState(() => _selected = tool),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: SectionLabel('Coming later'),
                      ),
                      for (final group in upcomingToolGroups) ...[
                        const SizedBox(height: 10),
                        _UpcomingGroup(group: group),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            ResponsiveCenter(
              maxWidth: 440,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('tool_continue_button'),
                    onPressed: _continue,
                    child: Text('Continue with ${_selected.displayName}'),
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

/// The tool's brand mark on its own colour — the one place a tool's brand
/// colour is drawn (P14 decision 4). A near-black brand (GitHub) is drawn
/// reversed in dark mode so the tile doesn't vanish into the card.
class _ToolMark extends StatelessWidget {
  const _ToolMark({required this.tool});

  final CiTool tool;

  static const size = 44.0;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reversed = isDark && tool.accentColor.computeLuminance() < 0.05;
    final background = reversed ? t.text : tool.accentColor;
    final foreground = reversed ? tool.accentColor : Colors.white;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * 0.27),
        ),
        child: Icon(tool.icon, size: size * 0.5, color: foreground),
      ),
    );
  }
}

class _ToolOption extends StatelessWidget {
  const _ToolOption({
    required this.tool,
    required this.selected,
    required this.onTap,
  });

  final CiTool tool;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const radius = BorderRadius.all(Radius.circular(16));

    return Semantics(
      key: Key('tool_card_${tool.name}'),
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '${tool.displayName}, ${tool.tagline}',
      excludeSemantics: true,
      child: Material(
        color: t.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? colorScheme.primary : t.cardBorder,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _ToolMark(tool: tool),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tool.displayName, style: textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(tool.tagline, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? colorScheme.primary : Colors.transparent,
                    border: selected
                        ? null
                        : Border.all(color: colorScheme.outline, width: 2),
                  ),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One category of tools that aren't available yet (`upcoming_tools.dart`):
/// names only, not selectable. Read out as one sentence per category, so a
/// screen reader doesn't step through dozens of disabled items.
class _UpcomingGroup extends StatelessWidget {
  const _UpcomingGroup({required this.group});

  final UpcomingToolGroup group;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      key: Key('upcoming_${group.name}'),
      enabled: false,
      label: '${group.name}, coming later: ${group.tools.join(', ')}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: t.chrome,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              style: textTheme.labelLarge?.copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tool in group.tools)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: t.raised,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tool,
                      style: textTheme.bodySmall?.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
