import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/common_widgets/status_indicator.dart';

void main() {
  testWidgets('exposes a screen-reader label describing the job status', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusIndicator(color: 'blue')),
      ),
    );

    expect(find.bySemanticsLabel('Success'), findsOneWidget);
  });

  testWidgets('appends "building" to the label for an _anime color', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusIndicator(color: 'blue_anime')),
      ),
    );

    expect(find.bySemanticsLabel('Success, building'), findsOneWidget);
  });

  testWidgets('falls back to "Unknown status" for an unrecognized color', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatusIndicator(color: null))),
    );

    expect(find.bySemanticsLabel('Unknown status'), findsOneWidget);
  });
}
