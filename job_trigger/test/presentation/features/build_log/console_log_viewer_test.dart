import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/features/build_log/console_log_viewer.dart';

/// P5-13: confirms the actual virtualization behavior (the thing that
/// makes thousands of lines performant) against a genuinely large fixture,
/// rather than a device-jank measurement -- there's no Android
/// device/emulator available in this environment to run that on (same
/// limitation as the manual-test gaps in earlier phases), so this is the
/// strongest check available here, not a substitute for the real thing.
void main() {
  testWidgets(
    'renders a 5,000-line log without building all 5,000 Text widgets at once',
    (tester) async {
      final lines = List.generate(
        5000,
        (i) => 'line $i: some representative log output here',
      );
      final text = lines.join('\n');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ConsoleLogViewer(text: text)),
        ),
      );
      await tester.pump();

      // ListView.builder only realizes what fits on screen (+ a small
      // cache extent) -- nowhere near all 5,000 lines should exist as
      // live Text widgets simultaneously. This is the actual property
      // that keeps scrolling smooth at scale.
      final realizedTextWidgets = find.byType(Text).evaluate().length;
      expect(realizedTextWidgets, lessThan(200));
      expect(realizedTextWidgets, greaterThan(0));
    },
  );

  testWidgets('scrolling to the bottom and back does not throw or hang', (
    tester,
  ) async {
    final lines = List.generate(5000, (i) => 'line $i');
    final text = lines.join('\n');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ConsoleLogViewer(text: text)),
      ),
    );
    await tester.pump();

    await tester.fling(find.byType(ListView), const Offset(0, -20000), 3000);
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView), const Offset(0, 20000), 3000);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('appending new lines while auto-scroll is on does not throw', (
    tester,
  ) async {
    var text = List.generate(200, (i) => 'line $i').join('\n');

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: Scaffold(
            body: ConsoleLogViewer(text: text),
            floatingActionButton: FloatingActionButton(
              onPressed: () => setState(() {
                text = '$text\nline ${200 + 1}';
              }),
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
  });
}
