import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/error_message.dart';
import '../../../domain/jenkins/console_decoder.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import 'build_log_notifier.dart';
import 'console_log_viewer.dart';
import 'console_notifiers.dart';

/// Ported from `BuildLogView.swift`, rebuilt for US-JX-07: search with
/// highlights, jump to first error, ANSI colors, timestamps, wrap and font
/// size, and saving the full log. [jenkinsBuild] comes from navigation
/// `extra`. A non-build log (e.g. a multibranch scan) sets its title in
/// `displayName`.
class BuildLogScreen extends ConsumerStatefulWidget {
  const BuildLogScreen({super.key, required this.jenkinsBuild});

  final JenkinsBuild jenkinsBuild;

  @override
  ConsumerState<BuildLogScreen> createState() => _BuildLogScreenState();
}

class _BuildLogScreenState extends ConsumerState<BuildLogScreen> {
  final _viewerKey = GlobalKey<ConsoleLogViewerState>();
  bool _searching = false;

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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: GlassAppBar(
        // The console is always black regardless of light/dark mode, so its
        // chrome is pinned to dark glass tokens too.
        brightness: Brightness.dark,
        title: _searching ? _SearchField(buildUrl: _url) : Text(_title),
        actions: [
          if (_searching) ...[
            Center(child: Text(search.counter)),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              tooltip: 'Previous match',
              onPressed: search.matches.isEmpty
                  ? null
                  : ref
                        .read(consoleSearchNotifierProvider(_url).notifier)
                        .previous,
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              tooltip: 'Next match',
              onPressed: search.matches.isEmpty
                  ? null
                  : ref.read(consoleSearchNotifierProvider(_url).notifier).next,
            ),
          ],
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: _searching ? 'Close search' : 'Search log',
            onPressed: () {
              if (_searching) {
                ref
                    .read(consoleSearchNotifierProvider(_url).notifier)
                    .setQuery('');
              }
              setState(() => _searching = !_searching);
            },
          ),
          if (!_searching)
            IconButton(
              icon: const Icon(Icons.error_outline),
              tooltip: 'Jump to first error',
              onPressed: log == null ? null : () => _jumpToFirstError(log),
            ),
          _MenuButton(
            prefs: prefs,
            enabled: log != null,
            exporting: exporting,
            onSelected: (action) => _onMenu(action, prefs, log),
          ),
        ],
      ),
      // Wider than the default ResponsiveCenter max width: log lines
      // benefit from horizontal room on a desktop window.
      body: ResponsiveCenter(
        maxWidth: 1200,
        child: logAsync.when(
          skipLoadingOnRefresh: true,
          data: (log) => Column(
            children: [
              SizedBox(
                height: MediaQuery.paddingOf(context).top + kToolbarHeight,
              ),
              if (log.isPartial)
                _Banner(
                  icon: Icons.content_cut,
                  text:
                      'Showing the last ${log.visibleLines.length} lines. '
                      'Save the full log to see everything.',
                ),
              if (prefs.timestamps && timestamps.embedded)
                const SizedBox.shrink()
              else if (prefs.timestamps && timestamps.pluginMissing)
                const _Banner(
                  icon: Icons.schedule,
                  text: "This server doesn't have the Timestamper plugin.",
                )
              else if (prefs.timestamps &&
                  !log.streaming &&
                  timestamps.values.isNotEmpty &&
                  timestamps.isEmpty)
                const _Banner(
                  icon: Icons.schedule,
                  text: 'No timestamps were recorded for this build.',
                ),
              if (log.reconnecting)
                const _Banner(
                  icon: Icons.wifi_off,
                  text: 'Connection lost — retrying…',
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
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: ConnectionErrorView(
              message: describeError(error),
              onRetry: () => ref.invalidate(buildLogNotifierProvider(_url)),
            ),
          ),
        ),
      ),
    );
  }

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

class _SearchField extends ConsumerWidget {
  const _SearchField({required this.buildUrl});

  final String buildUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      autofocus: true,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: const InputDecoration(
        hintText: 'Search log',
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
      onChanged: ref
          .read(consoleSearchNotifierProvider(buildUrl).notifier)
          .setQuery,
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
          : const Icon(Icons.more_vert),
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
        const PopupMenuItem(value: _MenuAction.copy, child: Text('Copy')),
        const PopupMenuItem(value: _MenuAction.share, child: Text('Share')),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF263238),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
