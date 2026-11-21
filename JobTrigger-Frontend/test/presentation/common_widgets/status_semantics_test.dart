import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_colors.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/core/theme/app_tokens.dart';
import 'package:job_trigger/presentation/common_widgets/status_indicator.dart';
import 'package:job_trigger/presentation/common_widgets/status_pill.dart';
import 'package:job_trigger/presentation/common_widgets/status_tile.dart';

/// US-DESIGN-05: build status is legible without colour.
Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  test('every tone has its own icon shape', () {
    final icons = {for (final t in StatusTone.values) StatusTile.iconFor(t)};
    expect(icons, hasLength(StatusTone.values.length));
  });

  test('every build result has a word', () {
    expect(StatusPill.labelForBuildResult('SUCCESS'), 'Success');
    expect(StatusPill.labelForBuildResult('FAILURE'), 'Failed');
    expect(StatusPill.labelForBuildResult('UNSTABLE'), 'Unstable');
    expect(StatusPill.labelForBuildResult('ABORTED'), 'Aborted');
    expect(StatusPill.labelForBuildResult('NOT_BUILT'), 'Not built');
  });

  testWidgets('a running build reads "Running" on the running tint', (
    tester,
  ) async {
    await _pump(tester, StatusPill.forBuildResult(null));

    expect(find.text('Running'), findsOneWidget);
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(StatusPill),
        matching: find.byType(DecoratedBox),
      ),
    );
    final tint = AppTokens.light.status(StatusTone.running).background;
    expect((box.decoration as BoxDecoration).color, tint);
  });

  testWidgets('a building job pulses; a finished one is still', (tester) async {
    await _pump(tester, const StatusIndicator(color: 'blue_anime'));
    expect(tester.hasRunningAnimations, isTrue);

    await _pump(tester, const StatusIndicator(color: 'blue'));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
