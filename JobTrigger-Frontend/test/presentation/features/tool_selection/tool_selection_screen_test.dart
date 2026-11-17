import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/app_info_repository_impl.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';
import 'package:job_trigger/domain/app_info/app_info_repository.dart';
import 'package:job_trigger/presentation/features/tool_selection/active_tool_notifier.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';
import 'package:job_trigger/presentation/features/tool_selection/tool_selection_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';

class _AppInfo implements AppInfoRepository {
  _AppInfo(this.supportEmail);

  final String? supportEmail;

  @override
  Future<Result<AppInfo, AppFailure>> fetchAppInfo() async => Ok(
    AppInfo(appVersion: '1.0.0', buildNumber: '1', supportEmail: supportEmail),
  );
}

/// P14-05: choose a tool, then Continue (`UI-UX/screens/03-tool-selection`).
void main() {
  late ProviderContainer container;

  Future<void> pumpScreen(
    WidgetTester tester, {
    String? supportEmail = 'support@jobtrigger.app',
  }) async {
    container = ProviderContainer(
      overrides: [
        appInfoRepositoryProvider.overrideWithValue(_AppInfo(supportEmail)),
      ],
    );
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

  testWidgets('only tools that work are offered — no coming-later list', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Jenkins'), findsOneWidget);
    expect(find.text('GitHub Actions'), findsOneWidget);
    expect(find.text('GitLab CI'), findsNothing);
    expect(find.textContaining('oming later'), findsNothing);
  });

  testWidgets('offers to request another tool when support has an address', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Need another tool? Tell us'), findsOneWidget);
  });

  testWidgets('no support address, no request link', (tester) async {
    await pumpScreen(tester, supportEmail: null);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tool_request_link')), findsNothing);
  });

  test('the request is a pre-addressed email', () {
    final uri = toolRequestUri('support@jobtrigger.app');

    expect(uri.scheme, 'mailto');
    expect(uri.path, 'support@jobtrigger.app');
    expect(uri.queryParameters['subject'], 'JobTrigger tool request');
  });
}
