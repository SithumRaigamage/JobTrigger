import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/console_decoder.dart';
import 'package:job_trigger/presentation/features/build_log/console_log_viewer.dart';
import 'package:job_trigger/presentation/features/build_log/console_notifiers.dart';

/// US-LOG-02: following the latest output, and the user's override.
List<ConsoleLine> _lines(int count) => ConsoleDecoder().addChunk(
  [for (var i = 0; i < count; i++) 'step $i of the build\n'].join(),
);

class _Harness {
  final key = GlobalKey<ConsoleLogViewerState>();
  final follows = <bool>[];
  late StateSetter _set;
  List<ConsoleLine> lines = _lines(200);

  Widget build() => MaterialApp(
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) {
          _set = setState;
          return ConsoleLogViewer(
            key: key,
            lines: lines,
            prefs: const ConsolePrefs(foldSections: false),
            onFollowChanged: follows.add,
          );
        },
      ),
    ),
  );

  /// More output arrives, as from the next progressive fetch.
  Future<void> grow(WidgetTester tester, int count) async {
    _set(() => lines = _lines(count));
    await tester.pumpAndSettle();
  }
}

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

bool _atEnd(WidgetTester tester) {
  final p = _position(tester);
  return p.pixels >= p.maxScrollExtent - 1;
}

void main() {
  testWidgets('new output keeps the latest line in view by default', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await h.grow(tester, 400);

    expect(_atEnd(tester), isTrue);
    expect(h.key.currentState!.following, isTrue);
  });

  testWidgets('scrolling up stops following; new output stays put', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await h.grow(tester, 400);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(h.key.currentState!.following, isFalse);
    expect(h.follows.last, isFalse);
    final before = _position(tester).pixels;

    await h.grow(tester, 600);
    expect(_position(tester).pixels, before);
    expect(_atEnd(tester), isFalse);
  });

  testWidgets('Follow jumps to the latest line and follows again', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await h.grow(tester, 400);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();

    h.key.currentState!.follow();
    await tester.pump();
    expect(_atEnd(tester), isTrue);
    expect(h.key.currentState!.following, isTrue);

    await h.grow(tester, 600);
    expect(_atEnd(tester), isTrue);
  });

  testWidgets('scrolling back to the bottom resumes following by itself', (
    tester,
  ) async {
    final h = _Harness();
    await tester.pumpWidget(h.build());
    await h.grow(tester, 400);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(h.key.currentState!.following, isFalse);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -5000));
    await tester.pumpAndSettle();

    expect(h.key.currentState!.following, isTrue);
    expect(h.follows.last, isTrue);
  });
}
