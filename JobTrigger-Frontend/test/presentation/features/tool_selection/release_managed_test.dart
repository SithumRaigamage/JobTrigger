import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';
import 'package:job_trigger/domain/tools/tool_catalog.dart';
import 'package:job_trigger/presentation/features/app_info/app_info_notifier.dart';
import 'package:job_trigger/presentation/features/settings/settings_screen.dart';
import 'package:job_trigger/presentation/features/tool_selection/active_tool_notifier.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';
import 'package:job_trigger/presentation/features/tool_selection/tool_selection_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../../support/plan_gates.dart';

/// Release-managed tools (design `release-1.0` / `release-1.1`): the screens
/// follow `release/tools.json`. Every other test runs with an all-tools
/// catalogue (`flutter_test_config.dart`); these set their own and restore it.
class _Info extends AppInfoNotifier {
  @override
  Future<AppInfo> build() async => const AppInfo(
    appVersion: '1.0.0',
    buildNumber: '1',
    supportEmail: 'support@jobtrigger.app',
  );
}

class _GitHubActive extends ActiveToolNotifier {
  @override
  CiTool? build() => CiTool.githubActions;
}

ToolCatalog release(String version) => ToolCatalog(
  release: version,
  versions: ToolCatalog.parse(
    File('config/tools.json').readAsStringSync(),
  ).versions,
);

/// The shipped manifest releases all three built tools at 1.0. This staged
/// fixture keeps the single-tool and two-tool screens (and their "Coming next"
/// tiles) covered without changing the release schedule in tools.json.
ToolCatalog staged(String version) => ToolCatalog(
  release: version,
  versions: const {
    'jenkins': '1.0',
    'sonarqube': '1.1',
    'githubActions': '1.2',
    'gitlab': '1.3',
    'circleci': '1.3',
  },
);

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });
  tearDown(() => ToolCatalog.current = ToolCatalog.allTools);

  Future<ProviderContainer> pumpSelection(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [appInfoNotifierProvider.overrideWith(_Info.new)],
    );
    addTearDown(container.dispose);
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
    await tester.pumpAndSettle();
    return container;
  }

  group('tool selection', () {
    testWidgets('release 1.0: three tools to choose, two tiles under '
        '"Coming next" with their versions', (tester) async {
      ToolCatalog.current = release('1.0');
      await pumpSelection(tester);

      expect(find.text('What do you build with?'), findsOneWidget);
      expect(
        find.text(
          'Jenkins for builds · GitHub Actions for workflows · '
          'SonarQube for code quality.',
        ),
        findsOneWidget,
      );
      for (final tool in ['jenkins', 'githubActions', 'sonarqube']) {
        expect(
          find.byKey(Key('tool_card_$tool')),
          findsOneWidget,
          reason: tool,
        );
      }
      for (final tool in ['gitlab', 'circleci']) {
        expect(find.byKey(Key('tool_card_$tool')), findsNothing, reason: tool);
        expect(
          find.byKey(Key('coming_next_$tool')),
          findsOneWidget,
          reason: tool,
        );
      }
      expect(find.text('COMING NEXT'), findsOneWidget);
      for (final (name, version) in [
        ('GitLab CI', '1.3'),
        ('CircleCI', '1.3'),
      ]) {
        final tile = find.ancestor(
          of: find.text(name),
          matching: find.byKey(Key('coming_next_${_idOf(name)}')),
        );
        expect(tile, findsOneWidget, reason: name);
        expect(
          find.descendant(of: tile, matching: find.text(version)),
          findsOneWidget,
          reason: name,
        );
      }
      expect(find.text('Continue with Jenkins'), findsOneWidget);
      // The roadmap link waits for a catalogue screen.
      expect(find.textContaining('roadmap'), findsNothing);
    });

    testWidgets('a one-tool release: Jenkins alone, the rest under '
        '"Coming next" with their versions', (tester) async {
      ToolCatalog.current = staged('1.0');
      await pumpSelection(tester);

      expect(find.text('Connect your Jenkins'), findsOneWidget);
      expect(
        find.text(
          'JobTrigger 1.0 works with Jenkins. More tools arrive in the next '
          'releases.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('tool_card_jenkins')), findsOneWidget);
      for (final tool in ['githubActions', 'sonarqube', 'gitlab', 'circleci']) {
        expect(find.byKey(Key('tool_card_$tool')), findsNothing, reason: tool);
        expect(find.byKey(Key('coming_next_$tool')), findsOneWidget);
      }
      expect(find.text('COMING NEXT'), findsOneWidget);
      for (final (name, version) in [
        ('SonarQube', '1.1'),
        ('GitHub Actions', '1.2'),
        ('GitLab CI', '1.3'),
        ('CircleCI', '1.3'),
      ]) {
        final tile = find.ancestor(
          of: find.text(name),
          matching: find.byKey(Key('coming_next_${_idOf(name)}')),
        );
        expect(tile, findsOneWidget, reason: name);
        expect(
          find.descendant(of: tile, matching: find.text(version)),
          findsOneWidget,
          reason: name,
        );
      }
      expect(find.text('Continue with Jenkins'), findsOneWidget);
      expect(find.textContaining('roadmap'), findsNothing);
    });

    testWidgets('the tiles are disabled: tapping one selects nothing', (
      tester,
    ) async {
      ToolCatalog.current = release('1.0');
      final container = await pumpSelection(tester);

      await tester.tap(find.byKey(const Key('coming_next_gitlab')));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Jenkins'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tool_continue_button')));
      await tester.pumpAndSettle();
      expect(container.read(activeToolNotifierProvider), CiTool.jenkins);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('the tiles are laid out in three columns', (tester) async {
      // A staged manifest: the shipped 1.0 has only two "Coming next" tiles.
      ToolCatalog.current = staged('1.0');
      await pumpSelection(tester);

      final tops = [
        for (final tool in ['sonarqube', 'githubActions', 'gitlab', 'circleci'])
          tester.getTopLeft(find.byKey(Key('coming_next_$tool'))),
      ];
      expect(tops[0].dy, tops[1].dy);
      expect(tops[1].dy, tops[2].dy);
      expect(tops[3].dy, greaterThan(tops[0].dy));
      expect(tops[3].dx, tops[0].dx);
    });

    testWidgets('release 1.1: two tools to choose, three tiles left', (
      tester,
    ) async {
      ToolCatalog.current = staged('1.1');
      await pumpSelection(tester);

      expect(find.text('What do you build with?'), findsOneWidget);
      expect(find.byKey(const Key('tool_card_jenkins')), findsOneWidget);
      expect(find.byKey(const Key('tool_card_sonarqube')), findsOneWidget);
      expect(find.byKey(const Key('tool_card_githubActions')), findsNothing);
      expect(
        find.byKey(const Key('coming_next_githubActions')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('coming_next_sonarqube')), findsNothing);
    });

    testWidgets('every tool released: no "Coming next" at all', (tester) async {
      // The all-tools catalogue the rest of the suite runs with.
      await pumpSelection(tester);

      expect(find.byKey(const Key('coming_next')), findsNothing);
      expect(find.text('What do you build with?'), findsOneWidget);
    });
  });

  group('settings', () {
    Future<void> pumpSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeToolNotifierProvider.overrideWith(_GitHubActive.new),
            ...savedCredentials(
              jenkins: [jenkinsServerNamed('a')],
              github: [gitHubCredentialNamed('g')],
            ),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a tool this release does not offer shows no section; '
        'Jenkins does, and what is saved is left alone', (tester) async {
      ToolCatalog.current = staged('1.0');
      await pumpSettings(tester);

      expect(find.text('JENKINS SERVERS'), findsOneWidget);
      expect(find.text('GITHUB'), findsNothing);
      expect(find.text('g'), findsNothing);
    });

    testWidgets('once the tool is released its section shows', (tester) async {
      await pumpSettings(tester);

      expect(find.text('GITHUB'), findsOneWidget);
      expect(find.text('JENKINS SERVERS'), findsNothing);
    });
  });
}

String _idOf(String name) => switch (name) {
  'SonarQube' => 'sonarqube',
  'GitHub Actions' => 'githubActions',
  'GitLab CI' => 'gitlab',
  _ => 'circleci',
};
