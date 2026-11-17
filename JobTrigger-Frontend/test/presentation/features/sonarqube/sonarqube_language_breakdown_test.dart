import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_language_breakdown.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_language_breakdown_view.dart';

Future<void> _pump(WidgetTester tester, Map<String, String> measures) =>
    tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SonarQubeLanguageBreakdownView(measures: measures),
            ),
          ),
        ),
      ),
    );

void main() {
  group('language breakdown section (US-SQ-QUALITY-13)', () {
    testWidgets('lists each language with its lines and share', (tester) async {
      await _pump(tester, {sonarQubeLanguageMetricKey: 'java=1200;js=340'});

      expect(find.text('LANGUAGES'), findsOne);
      expect(find.text('java'), findsOne);
      expect(find.text('1200 lines · 78%'), findsOne);
      expect(find.text('js'), findsOne);
      expect(find.text('340 lines · 22%'), findsOne);
    });

    testWidgets('is left off the page when the server has no distribution', (
      tester,
    ) async {
      await _pump(tester, {'coverage': '80.0'});

      expect(find.text('LANGUAGES'), findsNothing);
    });
  });
}
