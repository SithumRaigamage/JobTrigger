import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/console_decoder.dart';
import 'package:job_trigger/presentation/features/build_log/console_log_viewer.dart';
import 'package:job_trigger/presentation/features/build_log/console_notifiers.dart';

/// P5-13 (host-side part): the same shape as the fixture Jenkins `big-log`
/// pipeline — 50,000 ANSI-coloured lines with one error marker at line
/// 30,000. This checks the mechanism scales; it is NOT a substitute for the
/// on-device scroll-jank measurement, which needs an Android emulator/device.
const _lineCount = 50000;
const _errorLine = 30000;

String _log() => [
  for (var i = 1; i <= _lineCount; i++)
    i == _errorLine
        ? '\x1B[1;31mERROR\x1B[0m: fixture failure marker at line $i\n'
        : '\x1B[32mINFO\x1B[0m  line $i \x1B[2m(dim)\x1B[0m\n',
].join();

void main() {
  testWidgets('decodes and virtualizes a 50,000-line ANSI log', (tester) async {
    final sw = Stopwatch()..start();
    final lines = ConsoleDecoder().addChunk(_log());
    sw.stop();
    // Generous ceiling: catches an O(n^2) regression (AUD-12), not tuning.
    expect(sw.elapsedMilliseconds, lessThan(5000));
    expect(lines.length, greaterThanOrEqualTo(_lineCount));

    final key = GlobalKey<ConsoleLogViewerState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConsoleLogViewer(
            key: key,
            lines: lines,
            prefs: const ConsolePrefs(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widgetList(find.byType(RichText)).length, lessThan(200));

    // Fling a long way, then jump to the error marker: nothing may throw
    // and the live widget count must stay bounded throughout.
    for (var i = 0; i < 20; i++) {
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, -2000),
        4000,
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(tester.widgetList(find.byType(RichText)).length, lessThan(200));

    key.currentState!.jumpToLine(_errorLine - 1);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('fixture failure marker', findRichText: true),
      findsOneWidget,
    );
  });
}
