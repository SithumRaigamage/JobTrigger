import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/core/theme/app_tokens.dart';
import 'package:job_trigger/core/theme/reduce_transparency_notifier.dart';
import 'package:job_trigger/presentation/common_widgets/glass_surface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// US-DESIGN-01/03/04: where blur is used, and the opaque fallback.
Future<ProviderContainer> _pump(WidgetTester tester, Widget child) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// The fill colour of the surface's own DecoratedBox (the one with a
/// border).
Color _fill(WidgetTester tester, Finder surface) {
  final box = tester
      .widgetList<DecoratedBox>(
        find.descendant(of: surface, matching: find.byType(DecoratedBox)),
      )
      .map((b) => b.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.border != null);
  return box.color!;
}

Widget _bar() => const GlassSurface.chrome(
  key: Key('bar'),
  child: SizedBox(height: 64, width: 300, child: Text('Home')),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a card is opaque and never blurs', (tester) async {
    await _pump(
      tester,
      const GlassSurface.card(key: Key('card'), child: Text('row')),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    expect(_fill(tester, find.byKey(const Key('card'))), AppTokens.light.card);
  });

  testWidgets('the chrome bar frosts what scrolls beneath it', (tester) async {
    await _pump(tester, _bar());

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(_fill(tester, find.byKey(const Key('bar'))).a, lessThan(1));
  });

  testWidgets('a card inside the bar adds no blur of its own', (tester) async {
    await _pump(
      tester,
      const GlassSurface.chrome(
        child: GlassSurface.card(
          child: GlassSurface.card(child: Text('nested')),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('a long list of cards under the bar has one blur in total', (
    tester,
  ) async {
    await _pump(
      tester,
      Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 500,
              itemBuilder: (_, i) => GlassSurface.card(child: Text('row $i')),
            ),
          ),
          _bar(),
        ],
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('reduce transparency makes the bar opaque at once, same '
      'layout, border kept', (tester) async {
    final container = await _pump(tester, _bar());
    final bar = find.byKey(const Key('bar'));
    final frostedSize = tester.getSize(bar);

    await container
        .read(reduceTransparencyNotifierProvider.notifier)
        .setReduceTransparency(true);
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsNothing);
    expect(_fill(tester, bar), AppTokens.light.chrome);
    expect(_fill(tester, bar).a, 1);
    expect(tester.getSize(bar), frostedSize);

    // And back, without a restart.
    await container
        .read(reduceTransparencyNotifierProvider.notifier)
        .setReduceTransparency(false);
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('the setting survives a restart', (tester) async {
    SharedPreferences.setMockInitialValues({'reduce_transparency': true});
    await _pump(tester, _bar());

    expect(find.byType(BackdropFilter), findsNothing);
  });
}
