import 'package:flutter/material.dart';

/// A scrolling [body] with a [footer] (usually the primary button) that
/// sits at the bottom of the screen when there's room and scrolls with the
/// content when there isn't — the layout of the redesign's single-purpose
/// screens (`UI-UX/screens/01-login`, `03-tool-selection`, `19-open-link`).
class PinnedFooterLayout extends StatelessWidget {
  const PinnedFooterLayout({
    super.key,
    required this.body,
    required this.footer,
    this.padding = const EdgeInsets.fromLTRB(24, 40, 24, 24),
    this.maxWidth = 440,
  });

  final Widget body;
  final Widget footer;
  final EdgeInsets padding;

  /// Keeps the content a readable width on tablets and desktop windows.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minHeight: (constraints.maxHeight - padding.vertical).clamp(
                0,
                double.infinity,
              ),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  body,
                  const Spacer(),
                  const SizedBox(height: 24),
                  footer,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
