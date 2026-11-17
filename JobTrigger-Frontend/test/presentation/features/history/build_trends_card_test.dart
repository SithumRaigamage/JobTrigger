import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/presentation/features/history/build_trends_card.dart';

List<JenkinsBuild> _builds(int count) => [
  for (var i = count; i >= 1; i--)
    JenkinsBuild(
      number: i,
      url: 'u$i',
      result: i % 4 == 0 ? 'FAILURE' : 'SUCCESS',
      duration: 60000,
      timestamp: 0,
    ),
];

Future<void> _pump(WidgetTester tester, List<JenkinsBuild> builds) =>
    tester.pumpWidget(
      // GlassSurface reads the reduce-transparency preference.
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: BuildTrendsCard(builds: builds)),
        ),
      ),
    );

void main() {
  testWidgets('says when there are too few builds', (tester) async {
    await _pump(tester, _builds(3));
    expect(find.text('Not enough builds for trends'), findsOneWidget);
  });

  testWidgets('shows stats, an accessible chart, and switches window', (
    tester,
  ) async {
    await _pump(tester, _builds(60));

    // Last 20 are builds 41–60; 44, 48, 52, 56 and 60 failed: 75%.
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('1m 0s'), findsNWidgets(2));
    expect(
      find.bySemanticsLabel(RegExp('Duration of the last 20 builds')),
      findsOneWidget,
    );

    await tester.tap(find.text('50'));
    await tester.pump();
    expect(
      find.bySemanticsLabel(RegExp('Duration of the last 50 builds')),
      findsOneWidget,
    );
  });
}
