import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/presentation/common_widgets/labeled_field.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';
import 'package:job_trigger/presentation/features/app_info/app_info_notifier.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/nodes/nodes_screen.dart';
import 'package:job_trigger/presentation/features/queue/queue_screen.dart';
import 'package:job_trigger/presentation/features/settings/server_edit_bottom_sheet.dart';
import 'package:job_trigger/presentation/features/settings/settings_screen.dart';
import 'package:job_trigger/presentation/features/subscription/plan_gate.dart';
import 'package:job_trigger/presentation/features/subscription/pro_teaser.dart';
import 'package:job_trigger/presentation/features/tool_selection/active_tool_notifier.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';
import 'package:job_trigger/presentation/features/tool_selection/tool_selection_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../../../support/plan_gates.dart';

class _Info extends AppInfoNotifier {
  @override
  Future<AppInfo> build() async =>
      const AppInfo(appVersion: '1.0.0', buildNumber: '1');
}

/// P20-25: the blocked case opens the paywall *with the matching reason*.
/// The "paywall" here is a stand-in route that prints the reason it got.
Future<ProviderContainer> pump(
  WidgetTester tester,
  Widget screen, {
  required List<Override> overrides,
  String? start,
}) async {
  tester.view.physicalSize = const Size(800, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [appInfoNotifierProvider.overrideWith(_Info.new), ...overrides],
  );
  addTearDown(container.dispose);
  container.listen(activeToolNotifierProvider, (_, _) {});
  final router = GoRouter(
    initialLocation: start ?? '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, _) => screen),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (_, state) => Scaffold(
          body: Text('paywall:${state.uri.queryParameters['reason']}'),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  group('tool selection', () {
    Future<void> tapContinue(WidgetTester tester) async {
      final button = find.byKey(const Key('tool_continue_button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('Free with a Jenkins server: other tools carry a Pro mark, '
        'and choosing one opens the paywall for multiTool', (tester) async {
      final container = await pump(
        tester,
        const ToolSelectionScreen(),
        overrides: [
          gateOverride(freeGate),
          ...savedCredentials(jenkins: [jenkinsServerNamed('a')]),
        ],
      );

      expect(find.byKey(const Key('tool_pro_githubActions')), findsOneWidget);
      expect(find.byKey(const Key('tool_pro_sonarqube')), findsOneWidget);
      expect(find.byKey(const Key('tool_pro_jenkins')), findsNothing);

      await tester.tap(find.byKey(const Key('tool_card_githubActions')));
      await tester.pump();
      await tapContinue(tester);

      expect(find.text('paywall:multiTool'), findsOneWidget);
      // Nothing was committed.
      expect(container.read(activeToolNotifierProvider), isNull);
    });

    testWidgets('Free: the tool in use continues to Home', (tester) async {
      final container = await pump(
        tester,
        const ToolSelectionScreen(),
        overrides: [
          gateOverride(freeGate),
          ...savedCredentials(jenkins: [jenkinsServerNamed('a')]),
        ],
      );
      await tapContinue(tester);
      expect(find.text('home'), findsOneWidget);
      expect(container.read(activeToolNotifierProvider), CiTool.jenkins);
    });

    for (final (name, gate) in [
      ('Pro', proGate),
      ('billing off', PlanGate.open),
    ]) {
      testWidgets('$name: no marks, any tool continues', (tester) async {
        final container = await pump(
          tester,
          const ToolSelectionScreen(),
          overrides: [
            gateOverride(gate),
            ...savedCredentials(jenkins: [jenkinsServerNamed('a')]),
          ],
        );
        expect(find.byKey(const Key('tool_pro_githubActions')), findsNothing);
        await tester.tap(find.byKey(const Key('tool_card_githubActions')));
        await tester.pump();
        await tapContinue(tester);
        expect(find.text('home'), findsOneWidget);
        expect(
          container.read(activeToolNotifierProvider),
          CiTool.githubActions,
        );
      });
    }
  });

  group('insights teasers', () {
    testWidgets('a teaser opens the paywall with its reason', (tester) async {
      await pump(
        tester,
        const ProTeaser(
          reason: 'insights',
          title: 'Trends',
          message: 'Success rate and build times.',
        ),
        overrides: const [],
      );
      expect(find.text('Pro'), findsOneWidget);
      await tester.tap(find.text('See Pro'));
      await tester.pumpAndSettle();
      expect(find.text('paywall:insights'), findsOneWidget);
    });

    for (final (title, screen) in [
      ('Nodes', const NodesScreen()),
      ('Queue', const QueueScreen()),
    ]) {
      // No repository is overridden: the screen would fail loudly if it
      // fetched.
      testWidgets('Free: $title shows the teaser instead of fetching', (
        tester,
      ) async {
        await pump(tester, screen, overrides: [gateOverride(freeGate)]);
        expect(find.byType(ProTeaser), findsOneWidget);
        expect(find.text(title), findsOneWidget);
        await tester.tap(find.text('See Pro'));
        await tester.pumpAndSettle();
        expect(find.text('paywall:insights'), findsOneWidget);
      });
    }
  });

  group('locked credentials', () {
    testWidgets('a locked server is marked Pro, tapping it opens the paywall '
        'and does not switch to it', (tester) async {
      const locked = JenkinsServer(
        id: 'b',
        serverName: 'Locked server',
        jenkinsURL: 'https://b.test',
        username: 'u',
        secret: 's',
        locked: true,
      );
      await pump(
        tester,
        const SettingsScreen(),
        overrides: [
          gateOverride(freeGate),
          ...savedCredentials(jenkins: [jenkinsServerNamed('a'), locked]),
        ],
      );

      expect(find.text('Locked server'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);
      await tester.tap(find.text('Locked server'));
      await tester.pumpAndSettle();
      expect(find.text('paywall:locked'), findsOneWidget);
    });
  });

  group('add server', () {
    testWidgets('Free with a server saved: Add opens the paywall for '
        'maxCredentialsTotal and does not save', (tester) async {
      await pump(
        tester,
        const Scaffold(body: ServerEditBottomSheet()),
        overrides: [
          gateOverride(freeGate),
          ...savedCredentials(jenkins: [jenkinsServerNamed('a')]),
        ],
      );
      Finder field(String label) => find.descendant(
        of: find.widgetWithText(LabeledField, label),
        matching: find.byType(TextField),
      );
      await tester.enterText(field('Name'), 'Second');
      await tester.enterText(field('Server URL'), 'https://second.test');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('paywall:maxCredentialsTotal'), findsOneWidget);
    });
  });
}
