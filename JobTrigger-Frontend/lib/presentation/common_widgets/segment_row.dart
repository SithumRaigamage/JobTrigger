import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// How a [SegmentRow] draws one segment's label.
enum SegmentEmphasis {
  /// A finished or ordinary segment.
  normal,

  /// In progress: the label takes the running colour and a heavier weight.
  running,

  /// Never ran: the bar is the muted surface and the label is muted.
  notRun,
}

/// One segment of a [SegmentRow]: a status-coloured bar with a name under
/// it. Source-agnostic, so Jenkins pipeline stages (`US-PIPE-04`) and
/// GitHub job steps (`US-GH-RUN-05`) render identically.
class SegmentItem {
  const SegmentItem({
    required this.label,
    required this.semanticsLabel,
    required this.color,
    this.emphasis = SegmentEmphasis.normal,
    this.onTap,
  });

  final String label;

  /// Status in words for screen readers — never colour alone (NFR-A11Y-03).
  final String semanticsLabel;

  /// The bar colour; ignored for [SegmentEmphasis.notRun].
  final Color color;
  final SegmentEmphasis emphasis;
  final VoidCallback? onTap;
}

/// A row of [SegmentItem]s: up to [maxFitted] share the width equally; more
/// scroll sideways (`UI-UX/screens/11-job-detail`).
class SegmentRow extends StatelessWidget {
  const SegmentRow({super.key, required this.items, this.maxFitted = 5});

  final List<SegmentItem> items;
  final int maxFitted;

  @override
  Widget build(BuildContext context) {
    final segments = [for (final item in items) _Segment(item: item)];
    if (items.length <= maxFitted) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, segment) in segments.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: segment),
          ],
        ],
      );
    }
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: segments.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) =>
            SizedBox(width: 76, child: segments[index]),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.item});

  final SegmentItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final notRun = item.emphasis == SegmentEmphasis.notRun;
    final running = item.emphasis == SegmentEmphasis.running;
    return Semantics(
      button: item.onTap != null,
      label: item.semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: notRun ? t.raised : item.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: running ? FontWeight.w600 : FontWeight.w500,
                  color: running
                      ? t.running.foreground
                      : notRun
                      ? t.textMuted
                      : t.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
