import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_colors.dart';
import 'package:job_trigger/presentation/common_widgets/app_logo.dart';

void main() {
  Future<void> pumpLogo(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double size = 56,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(
        body: Center(child: AppLogo(size: size)),
      ),
    ),
  );

  AppLogoPainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byType(AppLogo),
                  matching: find.byType(CustomPaint),
                ),
              )
              .painter!
          as AppLogoPainter;

  testWidgets('draws the mark at the requested size', (tester) async {
    await pumpLogo(tester, size: 76);

    expect(tester.getSize(find.byType(AppLogo)), const Size.square(76));
  });

  testWidgets('has no outline in the light theme', (tester) async {
    await pumpLogo(tester);

    expect(painter(tester).outline, isNull);
  });

  testWidgets('outlines the navy tile in the dark theme', (tester) async {
    await pumpLogo(tester, brightness: Brightness.dark);

    expect(painter(tester).outline, AppColors.cardBorderDark);
  });

  testWidgets('is hidden from screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpLogo(tester);

    expect(
      find.descendant(
        of: find.byType(AppLogo),
        matching: find.byWidgetPredicate(
          (widget) => widget is ExcludeSemantics && widget.excluding,
        ),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  test('repaints only when the outline changes', () {
    const plain = AppLogoPainter();

    expect(plain.shouldRepaint(const AppLogoPainter()), isFalse);
    expect(
      plain.shouldRepaint(
        const AppLogoPainter(outline: AppColors.cardBorderDark),
      ),
      isTrue,
    );
  });
}
