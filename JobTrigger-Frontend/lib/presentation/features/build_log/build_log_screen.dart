import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/jenkins/console_decoder.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../common_widgets/responsive_center.dart';
import 'build_log_notifier.dart';
import 'console_log_viewer.dart';
import 'console_notifiers.dart';

/// Ported from `BuildLogView.swift`, rebuilt for US-JX-07: search with
/// highlights, jump to first error, ANSI colors, timestamps, wrap and font
/// size, and saving the full log. [jenkinsBuild] comes from navigation
/// `extra`. A non-build log (e.g. a multibranch scan) sets its title in
/// `displayName`. Laid out to the P14 design (`UI-UX/screens/15-build-log`).
class BuildLogScreen extends ConsumerStatefulWidget {
  const BuildLogScreen({super.key, required this.jenkinsBuild});

  final JenkinsBuild jenkinsBuild;

  @override
  ConsumerState<BuildLogScreen> createState() => _BuildLogScreenState();
}

class _BuildLogScreenState extends ConsumerState<BuildLogScreen> {
  final _viewerKey = GlobalKey<ConsoleLogViewerState>();

  /// Mirrors the viewer: on while new output scrolls into view.
  bool _following = true;

  String get _url => widget.jenkinsBuild.url;

  String get _title =>
      widget.jenkinsBuild.displayName ?? 'Build #${widget.jenkinsBuild.number}';

  @override
  Widget build(BuildContext context) {
    final logAsync = ref.watch(buildLogNotifierProvider(_url));
    final prefs = ref.watch(consolePrefsNotifierProvider);
    final search = ref.watch(consoleSearchNotifierProvider(_url));
    final timestamps = prefs.timestamps
        ? ref.watch(consoleTimestampsNotifierProvider(_url)).value ??
              ConsoleTimestamps.none
        : ConsoleTimestamps.none;
    final exporting = ref.watch(fullLogExportNotifierProvider(_url)).isLoading;
    final log = logAsync.value;

    // Follow the current search match as it changes.
    ref.listen(
      consoleSearchNotifierProvider(_url).select((s) => (s.query, s.current)),
      (_, _) {
        final line = ref.read(consoleSearchNotifierProvider(_url)).currentLine;
        if (line != null) _viewerKey.currentState?.jumpToLine(line);
      },
    );

    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final lineCount = log == null
        ? null
        : log.droppedLines + log.visibleLines.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text('Console', style: textTheme.titleMedium),
                        ),
                        Text(
                          [
                            _title,
                            if (lineCount != null)
                              '${_thousands(lineCount)} lines',
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.mono(
                            textTheme.bodySmall,
                          ).copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: 'Copy log',
                    onPressed: log == null
                        ? null
                        : () => _onMenu(_MenuAction.copy, prefs, log),
                  ),
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded, size: 20),
                    tooltip: 'Share log',
                    onPressed: log == null
                        ? null
                        : () => _onMenu(_MenuAction.share, prefs, log),
                  ),
                  _MenuButton(
                    prefs: prefs,
                    enabled: log != null,
                    exporting: exporting,
                    onSelected: (action) => _onMenu(action, prefs, log),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _SearchBar(buildUrl: _url, search: search),
            ),
            Expanded(
              child: ColoredBox(
                // The console is dark in both themes: build output is read
                // like a terminal, and its colours are measured on this.
                color: t.console,
                child: ResponsiveCenter(
                  // Wider than the default: log lines use the room on a
                  // desktop window.
                  maxWidth: 1200,
                  child: logAsync.when(
                    skipLoadingOnRefresh: true,
                    data: (log) => Column(
                      children: [
                        if (log.isPartial)
                          _Banner(
                            icon: Icons.content_cut_rounded,
                            text:
                                'Showing the last '
                                '${log.visibleLines.length} lines. Save the '
                                'full log to see everything.',
                          ),
                        if (prefs.timestamps && timestamps.embedded)
                          const SizedBox.shrink()
                        else if (prefs.timestamps && timestamps.pluginMissing)
                          const _Banner(
                            icon: Icons.schedule_rounded,
                            text:
                                "This server doesn't have the Timestamper "
                                'plugin.',
                          )
                        else if (prefs.timestamps &&
                            !log.streaming &&
                            timestamps.values.isNotEmpty &&
                            timestamps.isEmpty)
                          const _Banner(
                            icon: Icons.schedule_rounded,
                            text: 'No timestamps were recorded for this build.',
                          ),
                        if (log.reconnecting)
                          const _Banner(
                            icon: Icons.wifi_off_rounded,
                            text: 'Connection lost — retrying…',
                          ),
                        // AUD-64/NEW-05: Jenkins no longer has this build.
                        // Streaming has stopped for good, so this is a
                        // terminal state, not a transient one.
                        if (log.buildGone)
                          const _Banner(
                            icon: Icons.search_off_rounded,
                            text: 'This build no longer exists on the server.',
                          ),
                        Expanded(
                          child: ConsoleLogViewer(
                            key: _viewerKey,
                            lines: log.visibleLines,
                            prefs: prefs,
                            firstLineNumber: log.droppedLines,
                            timestamps: timestamps,
                            query: search.query,
                            currentMatchLine: search.currentLine,
                            onFollowChanged: (following) =>
                                setState(() => _following = following),
                          ),
                        ),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(
                      child: ConnectionErrorView(
                        message: describeError(error),
                        onRetry: () =>
                            ref.invalidate(buildLogNotifierProvider(_url)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: t.background,
                border: Border(top: BorderSide(color: t.cardBorder)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.failure.background,
                          foregroundColor: t.failure.foreground,
                        ),
                        onPressed: log == null
                            ? null
                            : () => _jumpToFirstError(log),
                        icon: const Icon(Icons.warning_amber_rounded, size: 18),
                        label: const Text('Jump to first error'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      toggled: _following,
                      child: OutlinedButton.icon(
                        style: _following
                            ? OutlinedButton.styleFrom(
                                backgroundColor: t.running.background,
                                foregroundColor: t.running.foreground,
                                side: BorderSide(color: t.running.dot),
                              )
                            : null,
                        onPressed: () => _viewerKey.currentState?.follow(),
                        icon: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 18,
                        ),
                        label: const Text('Follow'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `2481` → `2,481`.
  static String _thousands(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );

  void _jumpToFirstError(ConsoleState log) {
    final lines = log.visibleLines;
    final index = lines.indexWhere((line) => isErrorLine(line.text));
    if (index == -1) {
      _snack('No errors found in the loaded log');
      return;
    }
    _viewerKey.currentState?.jumpToLine(index);
  }

  Future<void> _onMenu(
    _MenuAction action,
    ConsolePrefs prefs,
    ConsoleState? log,
  ) async {
    final prefsNotifier = ref.read(consolePrefsNotifierProvider.notifier);
    switch (action) {
      case _MenuAction.wrap:
        await prefsNotifier.update(prefs.copyWith(wrap: !prefs.wrap));
      case _MenuAction.timestamps:
        await prefsNotifier.update(
          prefs.copyWith(timestamps: !prefs.timestamps),
        );
      case _MenuAction.smallerText:
        await prefsNotifier.update(
          prefs.copyWith(fontStep: (prefs.fontStep - 1).clamp(0, 2)),
        );
      case _MenuAction.largerText:
        await prefsNotifier.update(
          prefs.copyWith(fontStep: (prefs.fontStep + 1).clamp(0, 2)),
        );
      case _MenuAction.copy:
        if (log == null) return;
        await Clipboard.setData(ClipboardData(text: _plainText(log)));
        _snack('Log copied to clipboard');
      case _MenuAction.share:
        if (log == null) return;
        await SharePlus.instance.share(
          ShareParams(text: _plainText(log), subject: '$_title log'),
        );
      case _MenuAction.saveFull:
        await ref
            .read(fullLogExportNotifierProvider(_url).notifier)
            .export(fileName: '${_fileSafe(_title)}.log');
    }
  }

  static String _plainText(ConsoleState log) =>
      log.visibleLines.map((line) => line.text).join('\n');

  static String _fileSafe(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Always there above the console (`UI-UX/screens/15-build-log`): the
/// query, "2 / 3", and previous/next.
class _SearchBar extends ConsumerWidget {
  const _SearchBar({required this.buildUrl, required this.search});

  final String buildUrl;
  final ConsoleSearch search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(consoleSearchNotifierProvider(buildUrl).notifier);
    final mono = AppTypography.mono(Theme.of(context).textTheme.bodyMedium);
    return Semantics(
      label: 'Search log',
      child: TextField(
        style: mono,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search log',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: search.query.isEmpty
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(search.counter, style: mono.copyWith(fontSize: 12)),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up_rounded),
                      tooltip: 'Previous match',
                      onPressed: search.matches.isEmpty
                          ? null
                          : notifier.previous,
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      tooltip: 'Next match',
                      onPressed: search.matches.isEmpty ? null : notifier.next,
                    ),
                  ],
                ),
        ),
        onChanged: notifier.setQuery,
      ),
    );
  }
}

enum _MenuAction {
  wrap,
  timestamps,
  smallerText,
  largerText,
  copy,
  share,
  saveFull,
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.prefs,
    required this.enabled,
    required this.exporting,
    required this.onSelected,
  });

  final ConsolePrefs prefs;
  final bool enabled;
  final bool exporting;
  final ValueChanged<_MenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      tooltip: 'Log options',
      enabled: enabled,
      icon: exporting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.more_vert_rounded),
      onSelected: onSelected,
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: _MenuAction.wrap,
          checked: prefs.wrap,
          child: const Text('Wrap lines'),
        ),
        CheckedPopupMenuItem(
          value: _MenuAction.timestamps,
          checked: prefs.timestamps,
          child: const Text('Timestamps'),
        ),
        PopupMenuItem(
          value: _MenuAction.smallerText,
          enabled: prefs.fontStep > 0,
          child: const Text('Smaller text'),
        ),
        PopupMenuItem(
          value: _MenuAction.largerText,
          enabled: prefs.fontStep < 2,
          child: const Text('Larger text'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _MenuAction.saveFull,
          enabled: !exporting,
          child: const Text('Save full log (.log)'),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  static const _text = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _text),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: _text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
