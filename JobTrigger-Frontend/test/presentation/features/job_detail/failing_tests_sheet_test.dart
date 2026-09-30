import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_screen.dart';

void main() {
  testWidgets('lists failures, new ones first, with expandable details', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FailingTestsSheet(
            report: TestReport(
              passCount: 3,
              failCount: 5,
              skipCount: 0,
              failingTests: [
                FailingTest(name: 'old', className: 'com.x.A'),
                FailingTest(
                  name: 'divides',
                  className: 'com.x.Calc',
                  errorDetails: 'expected:<2> but was:<3>',
                  stackTrace:
                      'java.lang.AssertionError\n\tat Calc(Calc.java:42)',
                  isNewFailure: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('5 failing tests'), findsOneWidget);
    // New failure sorted first and badged.
    final titles = tester
        .widgetList<ExpansionTile>(find.byType(ExpansionTile))
        .map((tile) => (tile.title as Text).data)
        .toList();
    expect(titles, ['divides', 'old']);
    expect(find.text('New failure · com.x.Calc'), findsOneWidget);
    // Only 2 of 5 were sent (capped); the rest are acknowledged.
    expect(find.textContaining('3 more not shown'), findsOneWidget);

    await tester.tap(find.text('divides'));
    await tester.pumpAndSettle();
    expect(find.text('expected:<2> but was:<3>'), findsOneWidget);
    expect(find.textContaining('Calc.java:42'), findsOneWidget);
    expect(find.text('Copy stack trace'), findsOneWidget);
  });
}
