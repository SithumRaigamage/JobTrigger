import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

/// `ListView.builder` (not a single giant `Text` widget) so it stays smooth
/// at thousands of lines — only visible lines are ever built. Auto-scrolls
/// to the bottom on new data unless the user has scrolled up, matching
/// P5-11's requirement.
class ConsoleLogViewer extends StatefulWidget {
  const ConsoleLogViewer({super.key, required this.text});

  final String text;

  @override
  State<ConsoleLogViewer> createState() => _ConsoleLogViewerState();
}

class _ConsoleLogViewerState extends State<ConsoleLogViewer> {
  final _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 24;
    if (atBottom != _autoScroll) setState(() => _autoScroll = atBottom);
  }

  @override
  void didUpdateWidget(covariant ConsoleLogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text && _autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.text.split('\n');

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: lines.length,
          itemBuilder: (context, index) => Text(
            lines[index],
            style: AppTypography.buildLog.copyWith(color: Colors.white),
          ),
        ),
        if (!_autoScroll)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              onPressed: () {
                setState(() => _autoScroll = true);
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                }
              },
              child: const Icon(Icons.arrow_downward),
            ),
          ),
      ],
    );
  }
}
