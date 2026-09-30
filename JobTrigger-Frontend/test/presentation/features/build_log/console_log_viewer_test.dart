import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/console_decoder.dart';
import 'package:job_trigger/presentation/features/build_log/console_log_viewer.dart';
import 'package:job_trigger/presentation/features/build_log/console_notifiers.dart';

List<ConsoleLine> _lines(int count) => ConsoleDecoder().addChunk(
  [for (var i = 0; i < count; i++) 'line $i\n'].join(),
);

Future<GlobalKey<ConsoleLogViewerState>> _pump(
  WidgetTester tester,
  List<ConsoleLine> lines, {
  ConsolePrefs prefs = const ConsolePrefs(),
  String query = '',
  int? current,
  ConsoleTimestamps timestamps = ConsoleTimestamps.none,
}) async {
  final key = GlobalKey<ConsoleLogViewerState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ConsoleLogViewer(
          key: key,
          lines: lines,
          prefs: prefs,
          query: query,
          currentMatchLine: current,
          timestamps: timestamps,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

void main() {
  testWidgets('virtualizes a 5,000-line log', (tester) async {
    await _pump(tester, _lines(5000));
    expect(tester.widgetList(find.byType(RichText)).length, lessThan(200));
  });

  testWidgets('renders ANSI colors instead of stripping them', (tester) async {
    await _pump(tester, ConsoleDecoder().addChunk('\x1B[31mred\x1B[0m\n'));

    final rich = tester.widget<RichText>(find.byType(RichText).first);
    final spans = <TextSpan>[];
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text == 'red') spans.add(span);
      return true;
    });
    expect(
      spans.single.style?.color,
      consoleColor(const ConsoleColor.indexed(1)),
    );
  });

  testWidgets('highlights search matches', (tester) async {
    await _pump(
      tester,
      ConsoleDecoder().addChunk('build FAILED here\n'),
      query: 'failed',
      current: 0,
    );

    final rich = tester.widget<RichText>(find.byType(RichText).first);
    TextSpan? hit;
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text == 'FAILED') hit = span;
      return true;
    });
    expect(hit?.style?.backgroundColor, isNotNull);
  });

  for (final wrap in [true, false]) {
    testWidgets('jumpToLine brings a distant line on screen (wrap: $wrap)', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        _lines(3000),
        prefs: ConsolePrefs(wrap: wrap),
      );

      key.currentState!.jumpToLine(2000);
      await tester.pumpAndSettle();

      expect(find.text('line 2000', findRichText: true), findsOneWidget);
    });
  }

  testWidgets('no-wrap mode scrolls horizontally with fixed row heights', (
    tester,
  ) async {
    final long = ConsoleDecoder().addChunk('${'x' * 500}\n');
    await _pump(tester, long, prefs: const ConsolePrefs(wrap: false));

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows timestamps in a gutter when enabled', (tester) async {
    await _pump(
      tester,
      _lines(2),
      prefs: const ConsolePrefs(timestamps: true),
      timestamps: const ConsoleTimestamps(
        firstLine: 0,
        values: ['05:32:59', '05:33:01'],
      ),
    );

    expect(find.textContaining('05:33:01', findRichText: true), findsOneWidget);
  });
}
