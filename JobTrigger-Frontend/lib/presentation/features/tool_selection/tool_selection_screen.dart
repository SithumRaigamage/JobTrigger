import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/tools/tool_catalog.dart';
import '../../../domain/support/support_category.dart';
import '../../common_widgets/pinned_footer_layout.dart';
import '../../common_widgets/toast_controller.dart';
import '../../navigation/app_routes.dart';
import '../app_info/app_info_notifier.dart';
import '../subscription/locked_active_guard.dart';
import '../subscription/plan_gate.dart';
import 'active_tool_notifier.dart';
import 'ci_tool.dart';
import 'returning_tool_provider.dart';

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
  const ToolSelectionScreen({super.key, this.choosing = false});

  /// Opened to choose (Profile → CI tool, `/tools?choose=1`): always shows
  /// the picker. Otherwise a returning user goes straight Home (US-TOOL-01).
  final bool choosing;

  @override
  ConsumerState<ToolSelectionScreen> createState() =>
      _ToolSelectionScreenState();
}

class _ToolSelectionScreenState extends ConsumerState<ToolSelectionScreen> {
  /// The highlighted choice before Continue — the tool already in use when
  /// switching, Jenkins on first run.
  late CiTool _selected =
      ref.read(activeToolNotifierProvider) ?? CiTool.jenkins;

  /// US-TOOL-01: deciding whether this is a returning user.
  late bool _deciding = !widget.choosing;

  /// Set once the returning-user answer has been acted on.
  bool _decided = false;

  void _onReturning(AsyncValue<CiTool?> returning) {
    if (_decided || returning.isLoading) return;
    _decided = true;
    final tool = returning.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (tool == null) {
        setState(() => _deciding = false);
      } else {
        _selected = tool;
        unawaited(_continue());
      }
    });
  }

  Future<void> _continue() async {
    final notifier = ref.read(activeToolNotifierProvider.notifier);
    // P20-25: another tool than the one in use is part of Pro.
    final blocked = await notifier.blockedReason(_selected);
    if (!mounted) return;
    if (blocked != null) {
      await openPaywall(context, blocked);
      return;
    }
    // P20-25: the active credential of this tool was locked (a downgrade)
    // and replaced; say so once, on top of Home.
    final router = GoRouter.of(context);
    final locked = ref
        .read(lockedActiveGuardProvider.notifier)
        .consume(_selected);
    notifier.setActiveTool(_selected);
    router.go(AppRoutes.home);
    if (locked) unawaited(router.push(paywallLocation('locked')));
  }

  @override
  Widget build(BuildContext context) {
    if (_deciding) {
      // Watched, not read once: keeps the auto-disposed answer alive.
      _onReturning(ref.watch(returningToolProvider));
      return const Scaffold(
        key: Key('tool_selection_deciding'),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final available = CiTool.values.where((tool) => tool.isAvailable).toList();
    final single = available.length == 1;
    final comingNext = comingNextTools;
    final proTools = ref.watch(proLockedToolsProvider).value ?? const {};
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
                      // One released tool: nothing to choose, so say what
                      // this release does (design `release-1.0`).
                      single
                          ? 'Connect your ${available.first.displayName}'
                          : 'What do you build with?',
                      style: textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      single
                          ? 'JobTrigger ${ToolCatalog.current.release} works '
                                'with ${available.first.displayName}. More '
                                'tools arrive in the next releases.'
                          : 'Jenkins for builds · GitHub Actions for '
                                'workflows · SonarQube for code quality.',
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
                        pro: proTools.contains(tool),
                        onTap: () => setState(() => _selected = tool),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              if (comingNext.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ComingNext(tools: comingNext),
              ],
              if (supportEmail != null) ...[
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    key: const Key('tool_request_link'),
                    // P25-05: recorded as a ticket, so requests can be
                    // counted and answered instead of living in a mail box.
                    onPressed: () => context.push(
                      AppRoutes.support,
                      extra: SupportCategory.toolRequest,
                    ),
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
    this.pro = false,
    required this.onTap,
  });

  final CiTool tool;
  final bool selected;

  /// P20-25: needs Pro for this user; shows a mark.
  final bool pro;
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
      label:
          '${tool.displayName}, ${tool.tagline}${pro ? ', requires Pro' : ''}',
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tool.displayName,
                              style: textTheme.titleMedium,
                            ),
                          ),
                          if (pro) ...[
                            const SizedBox(width: 8),
                            Container(
                              key: Key('tool_pro_${tool.name}'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
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
                        ],
                      ),
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

/// "Coming next" (design `release-1.0`): the tools in the manifest that this
/// release doesn't offer yet, as a 3-column grid of disabled tiles with the
/// tool's name and the release it arrives in. Not selectable, not focusable
/// as a choice; a screen reader reads each as "tool, coming in version".
class _ComingNext extends StatelessWidget {
  const _ComingNext({required this.tools});

  final List<CiTool> tools;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return Column(
      key: const Key('coming_next'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'COMING NEXT',
              style: textTheme.labelSmall?.copyWith(
                color: t.textMuted,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Rows of three (the design's 3-column grid). Rows, not a Wrap in a
        // LayoutBuilder: this sits in PinnedFooterLayout, which measures its
        // body's intrinsic height.
        for (var start = 0; start < tools.length; start += 3) ...[
          if (start > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = start; i < start + 3; i++) ...[
                  if (i > start) const SizedBox(width: 10),
                  Expanded(
                    child: i < tools.length
                        ? _ComingNextTile(tool: tools[i])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ComingNextTile extends ConsumerWidget {
  const _ComingNextTile({required this.tool});

  final CiTool tool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final version = tool.releaseVersion ?? '';
    return Semantics(
      key: Key('coming_next_${tool.name}'),
      enabled: false,
      label: '${tool.displayName}, coming in $version',
      excludeSemantics: true,
      // US-TOOL-02: a tap selects nothing but says why, so the tile never
      // reads as broken.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref
            .read(toastControllerProvider)
            .show(
              type: ToastType.info,
              title: '${tool.displayName} is coming',
              message: version.isEmpty
                  ? 'It is not available yet.'
                  : 'It arrives in $version.',
            ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tool.shortLabel,
                  style: textTheme.labelLarge?.copyWith(
                    color: t.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tool.displayName,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: t.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                version,
                style: textTheme.labelSmall?.copyWith(
                  color: t.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
