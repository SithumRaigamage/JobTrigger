import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/settings/server_edit_bottom_sheet.dart';

/// P14-22: the edit sheets as redesigned (`UI-UX/screens/21-edit-server-sheet`).
const _server = JenkinsServer(
  id: 'a',
  serverName: 'Acme production',
  jenkinsURL: 'https://ci.acme.dev',
  username: 'sam',
  secret: 'fixture-secret',
);

/// Opens the sheet from a button and records what it completed with.
Future<List<bool?>> _open(
  WidgetTester tester, {
  JenkinsServer? existing,
}) async {
  final results = <bool?>[];
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => results.add(
                await showServerEditBottomSheet(context, existing: existing),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  testWidgets('editing offers delete, and asks the caller to do it', (
    tester,
  ) async {
    final results = await _open(tester, existing: _server);

    expect(find.text('Edit server'), findsOneWidget);
    await tester.ensureVisible(find.text('Delete server'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete server'));
    await tester.pumpAndSettle();

    expect(results, [true]);
  });

  testWidgets('cancel closes without asking to delete', (tester) async {
    final results = await _open(tester, existing: _server);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(results, [null]);
  });

  testWidgets('adding has nothing to delete', (tester) async {
    await _open(tester);

    expect(find.text('Add server'), findsOneWidget);
    expect(find.text('Delete server'), findsNothing);
  });
}
