import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/presentation/common_widgets/connection_error_view.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';

void _noop() {}

void main() {
  testWidgets('shows retry and a help action that can be overridden', (
    tester,
  ) async {
    var retries = 0;
    var helped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ConnectionErrorView(
          onRetry: () => retries++,
          onHelp: () => helped++,
        ),
      ),
    );

    expect(find.text('Retry Connection'), findsOneWidget);
    expect(find.text("Why can't I reach it?"), findsOneWidget);

    await tester.tap(find.text('Retry Connection'));
    await tester.tap(find.text("Why can't I reach it?"));
    expect(retries, 1);
    expect(helped, 1);
  });

  testWidgets('by default the help action opens the connection help route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const ConnectionErrorView(onRetry: _noop),
        ),
        GoRoute(
          path: AppRoutes.connectionHelp,
          builder: (context, state) => const Text('HELP ROUTE'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Why can't I reach it?"));
    await tester.pumpAndSettle();

    expect(find.text('HELP ROUTE'), findsOneWidget);
  });
}
