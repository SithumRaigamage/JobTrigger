import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/common_widgets/labeled_field.dart';
import 'package:job_trigger/presentation/features/settings/server_edit_bottom_sheet.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1800);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        // The sheet scrolls its own fields (P14-22).
        home: Scaffold(body: ServerEditBottomSheet()),
      ),
    ),
  );
}

/// Since P14-22 the label sits above the field, in a `LabeledField`.
Finder _field(String label) => find.descendant(
  of: find.widgetWithText(LabeledField, label),
  matching: find.byType(TextField),
);

Finder get _secretField => _field('API token');

void main() {
  testWidgets('a password-looking secret shows the token advisory (US-JX-22)', (
    tester,
  ) async {
    await _pump(tester);
    await tester.enterText(_field('Server URL'), 'https://ci.test');
    await tester.enterText(_secretField, 'hunter2');
    await tester.pump();

    expect(find.textContaining('This looks like a password'), findsOneWidget);
    expect(find.text('Create an API token'), findsOneWidget);
  });

  testWidgets('a real API token shows no advisory', (tester) async {
    await _pump(tester);
    await tester.enterText(_secretField, '118addfcc60b8573398ead1f701cb565a1');
    await tester.pump();

    expect(find.textContaining('This looks like a password'), findsNothing);
  });

  group('Jenkins URL field (AUD-14)', () {
    Finder urlField() => _field('Server URL');

    testWidgets('http:// shows the cleartext warning; https:// does not', (
      tester,
    ) async {
      await _pump(tester);
      await tester.enterText(urlField(), 'http://192.168.1.20:8080');
      await tester.pump();
      expect(find.textContaining('Not encrypted'), findsOneWidget);

      await tester.enterText(urlField(), 'https://ci.test');
      await tester.pump();
      expect(find.textContaining('Not encrypted'), findsNothing);
    });

    testWidgets('an unusable URL says why, inline', (tester) async {
      await _pump(tester);
      await tester.enterText(urlField(), 'ci.test');
      await tester.pump();
      expect(find.textContaining('must start with https://'), findsOneWidget);
    });
  });
}
