import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/domain/diagnostics/connection_diagnosis.dart';
import 'package:job_trigger/presentation/features/connectivity/connection_help_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';

void main() {
  testWidgets('lists all five common causes', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ConnectionHelpScreen()));

    expect(find.text("Why can't I reach it?"), findsWidgets);
    expect(find.text('WHAT TO CHECK'), findsOneWidget);
    for (final cause in connectionChecklist()) {
      expect(find.text(cause.title), findsOneWidget, reason: cause.title);
    }
    expect(find.text('Remote access guide'), findsOneWidget);
  });

  testWidgets('leads with the supplied diagnosis', (tester) async {
    final diagnosis = diagnoseConnection(
      'http://192.168.1.24:8080',
      const NetworkFailure(),
    );
    await tester.pumpWidget(
      MaterialApp(home: ConnectionHelpScreen(diagnosis: diagnosis)),
    );

    expect(
      find.text('Likely cause: A private address only works at home'),
      findsOneWidget,
    );
    expect(find.text(diagnosis.explanation), findsWidgets);
  });

  testWidgets('the guide row opens the remote access guide', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ConnectionHelpScreen(),
        ),
        GoRoute(
          path: AppRoutes.remoteAccessGuide,
          builder: (context, state) => const Text('GUIDE ROUTE'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Remote access guide'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Remote access guide'));
    await tester.pumpAndSettle();

    expect(find.text('GUIDE ROUTE'), findsOneWidget);
  });
}
