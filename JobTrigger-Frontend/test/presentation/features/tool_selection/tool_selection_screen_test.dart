import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/presentation/features/tool_selection/active_tool_notifier.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';
import 'package:job_trigger/presentation/features/tool_selection/tool_selection_screen.dart';
import 'package:job_trigger/presentation/features/tool_selection/upcoming_tools.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';

/// P14-05: choose a tool, then Continue (`UI-UX/screens/03-tool-selection`).
void main() {
  late ProviderContainer container;

  Future<void> pumpScreen(WidgetTester tester) async {
    container = ProviderContainer();
    addTearDown(container.dispose);
    // In the app the router and Home keep the active tool alive; the
    // provider is auto-disposed, so the test holds a listener the same way.
    container.listen(activeToolNotifierProvider, (_, _) {});
    final router = GoRouter(
      initialLocation: AppRoutes.toolSelection,
      routes: [
        GoRoute(
          path: AppRoutes.toolSelection,
          builder: (_, _) => const ToolSelectionScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
      ),
    );
  }

  Future<void> tapContinue(WidgetTester tester) async {
    final button = find.byKey(const Key('tool_continue_button'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('Jenkins is chosen to start with, and nothing is committed '
      'until Continue', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Continue with Jenkins'), findsOneWidget);
    expect(container.read(activeToolNotifierProvider), isNull);
  });

  testWidgets('choosing GitHub Actions and continuing commits it and goes '
      'home', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('tool_card_githubActions')));
    await tester.pump();
    expect(find.text('Continue with GitHub Actions'), findsOneWidget);

    await tapContinue(tester);
    expect(container.read(activeToolNotifierProvider), CiTool.githubActions);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('tools that are coming later cannot be chosen', (tester) async {
    await pumpScreen(tester);

    await tester.ensureVisible(find.text('GitLab CI'));
    await tester.pump();
    await tester.tap(find.text('GitLab CI'));
    await tester.pump();
    expect(find.text('Continue with Jenkins'), findsOneWidget);
  });

  testWidgets('every planned tool is listed under Coming later', (
    tester,
  ) async {
    await pumpScreen(tester);

    for (final group in upcomingToolGroups) {
      expect(find.text(group.name), findsOneWidget);
      for (final tool in group.tools) {
        expect(find.text(tool), findsOneWidget, reason: tool);
      }
    }
    // Shown, never selectable: none of them is a radio option.
    expect(find.text('Kubernetes'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Kubernetes,')), findsNothing);
  });
}
