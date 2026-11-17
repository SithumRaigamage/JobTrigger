import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/features/pairing/pair_screen.dart';

Future<void> _pump(WidgetTester tester, Map<String, String> query) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: PairScreen(query: query)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows what the code carried and offers to add it', (
    tester,
  ) async {
    await _pump(tester, const {
      'url': 'https://ci.example.com',
      'name': 'Acme production',
      'username': 'deploy',
    });

    expect(find.text('Acme production'), findsOneWidget);
    expect(find.text('https://ci.example.com'), findsOneWidget);
    expect(find.text('deploy'), findsOneWidget);
    expect(find.text('Add this server'), findsOneWidget);
    expect(find.textContaining('isn’t in the code'), findsOneWidget);
  });

  testWidgets('a code without a server says so', (tester) async {
    await _pump(tester, const {});

    expect(find.text('That code didn’t include a server'), findsOneWidget);
    expect(find.text('Add this server'), findsNothing);
  });

  testWidgets('an unusable address is refused before the form', (tester) async {
    await _pump(tester, const {'url': 'not a url', 'name': 'Broken'});

    expect(find.text('That server address can’t be used'), findsOneWidget);
    expect(find.text('Add this server'), findsNothing);
  });
}
