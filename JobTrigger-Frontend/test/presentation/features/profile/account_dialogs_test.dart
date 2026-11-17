import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/features/profile/account_dialogs.dart';

void main() {
  Future<bool?> open(WidgetTester tester, AccountAction onSubmit) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showDeleteAccountDialog(
              context,
              onSubmit: onSubmit,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'my-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('a refusal shows inline and keeps the dialog open', (
    tester,
  ) async {
    final sent = <List<String>>[];
    await open(tester, (values) async {
      sent.add(values);
      return 'Current password is incorrect';
    });
    expect(sent, [
      ['my-password'],
    ]);
    expect(find.text('Current password is incorrect'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('success closes the dialog and reports it', (tester) async {
    final result = await open(tester, (_) async => null);
    expect(find.byType(AlertDialog), findsNothing);
    expect(result, isTrue);
  });
}
