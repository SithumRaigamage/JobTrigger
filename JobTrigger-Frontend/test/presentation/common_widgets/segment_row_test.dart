import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/presentation/common_widgets/segment_row.dart';

SegmentItem _item(String label, {VoidCallback? onTap}) => SegmentItem(
  label: label,
  semanticsLabel: '$label, ok',
  color: Colors.green,
  onTap: onTap,
);

Future<void> _pump(WidgetTester tester, List<SegmentItem> items) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentRow(items: items),
          ),
        ),
      ),
    );

void main() {
  testWidgets('shows every label when few segments share the width', (
    tester,
  ) async {
    await _pump(tester, [_item('Build'), _item('Test'), _item('Deploy')]);

    expect(find.text('Build'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Deploy'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('more than five scroll sideways', (tester) async {
    await _pump(tester, [for (var i = 0; i < 8; i++) _item('S$i')]);

    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('a tapped segment fires its callback; others are inert', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, [_item('Build', onTap: () => taps++), _item('Test')]);

    await tester.tap(find.text('Build'));
    await tester.tap(find.text('Test'));

    expect(taps, 1);
  });

  testWidgets('status is exposed in words for screen readers', (tester) async {
    await _pump(tester, [_item('Build')]);

    expect(find.bySemanticsLabel('Build, ok'), findsOneWidget);
  });
}
