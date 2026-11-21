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
    // Folding off: these lines share a signature, and this test is about
    // the list building only the visible rows.
    await _pump(
      tester,
      _lines(5000),
      prefs: const ConsolePrefs(foldSections: false),
    );
    expect(tester.widgetList(find.byType(RichText)).length, lessThan(200));
  });

  // US-DESIGN-04 "Console is flat": no blur anywhere in it, and every
  // line carries its number in the gutter.
  testWidgets('the console is flat and numbers its lines', (tester) async {
    await _pump(
      tester,
      _lines(3),
      prefs: const ConsolePrefs(foldSections: false),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    final text = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.toPlainText())
        .join('\n');
    for (var i = 0; i < 3; i++) {
      expect(text, contains('${i + 1}'));
      expect(text, contains('line $i'));
    }
  });

  testWidgets('folds a noisy run into one row and opens it on tap', (
    tester,
  ) async {
    final lines = ConsoleDecoder().addChunk(
      [
        for (var i = 1; i <= 40; i++)
          'Waiting for next available executor $i\n',
        'Build finished\n',
      ].join(),
    );

    await _pump(tester, lines);

    expect(find.text('40 similar lines'), findsOneWidget);
    expect(
      find.textContaining('Waiting for next', findRichText: true),
      findsNothing,
    );

    await tester.tap(find.text('40 similar lines'));
    await tester.pumpAndSettle();

    expect(find.text('Hide 40 similar lines'), findsOneWidget);
    expect(
      find.textContaining('Waiting for next', findRichText: true),
      findsWidgets,
    );

    await tester.tap(find.text('Hide 40 similar lines'));
    await tester.pumpAndSettle();

    expect(find.text('40 similar lines'), findsOneWidget);
    expect(find.text('Hide 40 similar lines'), findsNothing);
  });

  testWidgets('folding can be turned off', (tester) async {
    final lines = ConsoleDecoder().addChunk(
      [
        for (var i = 1; i <= 40; i++)
          'Waiting for next available executor $i\n',
        'Build finished\n',
      ].join(),
    );

    await _pump(tester, lines, prefs: const ConsolePrefs(foldSections: false));

    expect(find.textContaining('similar lines'), findsNothing);
    expect(
      find.textContaining('Waiting for next', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('jumping to a line inside a folded run opens the run', (
    tester,
  ) async {
    final key = await _pump(tester, _lines(3000));

    expect(find.text('3000 similar lines'), findsOneWidget);

    key.currentState!.jumpToLine(2000);
    await tester.pumpAndSettle();

    expect(find.text('line 2000', findRichText: true), findsOneWidget);
  });

  testWidgets('a search match inside a folded run is revealed', (tester) async {
    final lines = ConsoleDecoder().addChunk(
      [for (var i = 0; i < 20; i++) 'retrying $i\n'].join(),
    );

    await _pump(tester, lines, query: 'retrying 7', current: 7);
    await tester.pumpAndSettle();

    expect(find.text('Hide 20 similar lines'), findsOneWidget);
    expect(find.text('retrying 7', findRichText: true), findsOneWidget);
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
