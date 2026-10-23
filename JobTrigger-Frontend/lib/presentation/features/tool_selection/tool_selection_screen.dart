import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../common_widgets/pinned_footer_layout.dart';
import '../../common_widgets/external_link.dart';
import '../../navigation/app_routes.dart';
import '../app_info/app_info_notifier.dart';
import 'active_tool_notifier.dart';
import 'ci_tool.dart';

/// Ported from `Tools/ToolSelection/ToolSelectionView.swift`, laid out to
/// the P14 design (`UI-UX/screens/03-tool-selection`): the available tools
/// as a single-choice list and a Continue button that commits the choice.
///
/// Only tools that work are shown. Planned ones live in `tasks/backlog.md`,
/// not here: a list of unbuilt tools is onboarding noise and a promise an
/// installed build can't take back. Instead, "Need another tool?" emails
/// support, so requests decide what's built next. Shown after login, and again
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
    // From `GET /api/appinfo`; no address, no link.
    final supportEmail = ref.watch(appInfoNotifierProvider).value?.supportEmail;

    return Scaffold(
      body: SafeArea(
        child: PinnedFooterLayout(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
          body: Column(
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
                      style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
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
              if (supportEmail != null) ...[
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    key: const Key('tool_request_link'),
                    onPressed: () =>
                        openExternalLink(ref, toolRequestUri(supportEmail)),
                    child: const Text('Need another tool? Tell us'),
                  ),
                ),
              ],
            ],
          ),
          footer: FilledButton(
            key: const Key('tool_continue_button'),
            onPressed: _continue,
            child: Text('Continue with ${_selected.displayName}'),
          ),
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

/// A pre-addressed email asking for a tool the app doesn't support yet.
Uri toolRequestUri(String supportEmail) => Uri(
  scheme: 'mailto',
  path: supportEmail,
  query:
      'subject=${Uri.encodeComponent('JobTrigger tool request')}'
      '&body=${Uri.encodeComponent('The CI/CD tool I would like to use: ')}',
);
