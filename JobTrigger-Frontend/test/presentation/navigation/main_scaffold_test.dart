import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/presentation/navigation/main_scaffold.dart';

/// A branch-root screen with local counter state (to prove
/// `.indexedStack` preserves it across tab switches) and a button that
/// pushes a second, go_router-managed route onto its own branch (to prove
/// re-tapping the active tab resets that branch back to its root). Uses
/// `context.push`, not a raw `Navigator.push`, to match how every real
/// screen in the app navigates (`context.push(AppRoutes...)`).
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('home-tab'),
            Text('count: $_count'),
            ElevatedButton(
              onPressed: () => setState(() => _count++),
              child: const Text('increment'),
            ),
            ElevatedButton(
              onPressed: () => context.push('/a/detail'),
              child: const Text('push detail'),
            ),
          ],
        ),
      ),
    );
  }
}

GoRouter _buildTestRouter() => GoRouter(
  initialLocation: '/a',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/a',
              builder: (context, state) => const _HomeTab(),
              routes: [
                GoRoute(
                  path: 'detail',
                  builder: (context, state) =>
                      const Scaffold(body: Center(child: Text('detail-page'))),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/b',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('history-tab'))),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/c',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('settings-tab'))),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/d',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('profile-tab'))),
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  testWidgets('tapping a destination switches to that branch', (tester) async {
    final router = _buildTestRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
      0,
    );

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
      1,
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });

  testWidgets('switching away and back preserves branch widget state', (
    tester,
  ) async {
    final router = _buildTestRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('increment'));
    await tester.tap(find.text('increment'));
    await tester.pumpAndSettle();
    expect(find.text('count: 2'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('settings-tab'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // .indexedStack keeps every branch's widget tree alive (not rebuilt
    // from scratch), so the counter must still read 2, not reset to 0.
    expect(find.text('count: 2'), findsOneWidget);
  });

  testWidgets('re-tapping the active tab resets that branch to its root', (
    tester,
  ) async {
    final router = _buildTestRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('push detail'));
    await tester.pumpAndSettle();
    expect(find.text('detail-page'), findsOneWidget);

    // Home is already the active tab -- tapping it again should pop the
    // pushed detail page and return to the branch's root route.
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('detail-page'), findsNothing);
    expect(find.text('home-tab'), findsOneWidget);
  });

  testWidgets(
    'system back from a non-Home tab returns to Home instead of exiting',
    (tester) async {
      final router = _buildTestRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        3,
      );

      final navigatorState = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      final popped = await navigatorState.maybePop();
      await tester.pumpAndSettle();

      // MainScaffold's outer PopScope intercepted the pop -- it switched
      // back to Home rather than letting the shell's own route pop (which
      // would exit the app).
      expect(popped, isTrue);
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        0,
      );
    },
  );

  testWidgets('system back at the Home tab lets the pop through', (
    tester,
  ) async {
    final router = _buildTestRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final navigatorState = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    final popped = await navigatorState.maybePop();
    await tester.pumpAndSettle();

    // Already on Home (index 0): MainScaffold's PopScope.canPop is true,
    // so the pop is allowed through normally (nothing left to pop to in
    // this minimal test router -- maybePop reports false).
    expect(popped, isFalse);
  });
}
