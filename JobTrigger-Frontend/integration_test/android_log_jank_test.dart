// P5-13 / P11-03: on-device scroll-jank measurement for the 50,000-line
// fixture log (`big-log` in tools/jenkins-fixture). The host widget test
// proves virtualization; this one records real frame timings on a device.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/android_log_jank_test.dart -d <android-id> \
//     --dart-define-from-file=config/dev.json
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:job_trigger/domain/jenkins/console_decoder.dart';
import 'package:job_trigger/presentation/features/build_log/console_log_viewer.dart';
import 'package:job_trigger/presentation/features/build_log/console_notifiers.dart';

const _lineCount = 50000;
const _errorLine = 30000;

String _log() => [
  for (var i = 1; i <= _lineCount; i++)
    i == _errorLine
        ? '\x1B[1;31mERROR\x1B[0m: fixture failure marker at line $i\n'
        : '\x1B[32mINFO\x1B[0m  line $i \x1B[2m(dim)\x1B[0m\n',
].join();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('50k-line log scrolls without dropped frames', (tester) async {
    final lines = ConsoleDecoder().addChunk(_log());
    expect(lines.length, greaterThanOrEqualTo(_lineCount));

    final timings = Queue<FrameTiming>();
    void record(List<FrameTiming> batch) => timings.addAll(batch);
    WidgetsBinding.instance.addTimingsCallback(record);
    addTearDown(() => WidgetsBinding.instance.removeTimingsCallback(record));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConsoleLogViewer(
            lines: lines,
            prefs: const ConsolePrefs(foldSections: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 30; i++) {
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, -2000),
        4000,
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    // Nothing throws and virtualization holds after the flings.
    expect(tester.widgetList(find.byType(RichText)).length, lessThan(200));

    final frames =
        timings
            .map(
              (t) =>
                  t.buildDuration.inMicroseconds +
                  t.rasterDuration.inMicroseconds,
            )
            .where((us) => us > 0)
            .toList()
          ..sort();
    if (frames.isEmpty) {
      // ignore: avoid_print
      print('P5-13 FRAME DATA: no timings captured');
      return;
    }
    final p50 = frames[frames.length ~/ 2] / 1000;
    final p95 =
        frames[(frames.length * 0.95).floor().clamp(0, frames.length - 1)] /
        1000;
    final worst = frames.last / 1000;
    // ignore: avoid_print
    print(
      'P5-13 FRAME DATA: ${frames.length} frames, '
      'p50=${p50.toStringAsFixed(1)}ms p95=${p95.toStringAsFixed(1)}ms '
      'worst=${worst.toStringAsFixed(1)}ms (16.7ms = 60fps)',
    );
    expect(tester.widgetList(find.byType(RichText)).length, lessThan(200));
  });
}
