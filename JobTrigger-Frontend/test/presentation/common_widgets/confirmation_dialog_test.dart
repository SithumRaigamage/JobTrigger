import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/presentation/common_widgets/confirmation_dialog.dart';

/// Lets a test reach the future the dialog will resolve before it is tapped.
class _DialogHost {
  Future<bool>? pending;
}

/// Pumps a host app, taps its button to open the dialog, and returns a handle
/// to the pending result. [requiredPhrase] is passed straight through.
Future<_DialogHost> _openDialog(
  WidgetTester tester, {
  String? requiredPhrase,
}) async {
  final host = _DialogHost();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () {
              host.pending = showConfirmationDialog(
                context,
                title: 'Deploy?',
                message: 'This starts a production build.',
                confirmLabel: 'Deploy',
                requiredPhrase: requiredPhrase,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return host;
}

void main() {
  testWidgets('no required phrase: one-step confirm stays enabled', (
    tester,
  ) async {
    final host = await _openDialog(tester);

    expect(find.text('Deploy?'), findsOneWidget);
    expect(find.byKey(const Key('confirmation_phrase_field')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Deploy'))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Deploy'));
    await tester.pumpAndSettle();
    expect(await host.pending, isTrue);
  });

  testWidgets('required phrase: confirm is disabled until the exact text '
      'is typed', (tester) async {
    final host = await _openDialog(tester, requiredPhrase: 'deploy-prod');

    final confirmFinder = find.widgetWithText(FilledButton, 'Deploy');
    expect(
      tester.widget<FilledButton>(confirmFinder).onPressed,
      isNull,
      reason: 'confirm starts disabled',
    );

    await tester.enterText(
      find.byKey(const Key('confirmation_phrase_field')),
      'deploy-pro',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(confirmFinder).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('confirmation_phrase_field')),
      'deploy-prod',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(confirmFinder).onPressed, isNotNull);

    await tester.tap(confirmFinder);
    await tester.pumpAndSettle();
    expect(await host.pending, isTrue);
  });

  testWidgets('dismissing a protected dialog counts as no', (tester) async {
    final host = await _openDialog(tester, requiredPhrase: 'deploy-prod');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await host.pending, isFalse);
  });
}
