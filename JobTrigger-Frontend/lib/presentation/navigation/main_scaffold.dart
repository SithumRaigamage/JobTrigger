import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Persistent bottom tab shell (P6-14). Wraps go_router's
/// `StatefulShellRoute.indexedStack` branches (Home/History/Settings/
/// Profile) in a Material 3 `NavigationBar`, replacing the AppBar
/// icon-button push pattern used through Phase 6 — see
/// `tasks/backlog.md`'s now-promoted bottom-tab-bar item and
/// `docs/architecture.md`'s mapping from the old `NavBarView.swift`.
///
/// A deliberate structural upgrade beyond the SwiftUI original: that app's
/// `TabView` had only 3 tabs (Home/History/Settings), with Profile reached
/// via a push-based "person.circle" icon repeated on each tab's toolbar.
/// Here Profile is a 4th persistent tab instead, removing that duplicated
/// icon button from 3 different AppBars.
///
/// Deliberately a plain `StatelessWidget`, not a Riverpod notifier — it
/// holds no state of its own; `navigationShell.currentIndex` and each
/// branch's navigation history are already owned by go_router.
class MainScaffold extends StatelessWidget {
  const MainScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Android convention (consistent with HomeScreen's own P6-06
        // breadcrumb PopScope): back from a non-Home tab returns to Home
        // first; a second back press once Home is active falls through to
        // HomeScreen's own PopScope / default exit behavior.
        navigationShell.goBranch(0);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            // Tapping the already-active tab resets that branch's stack
            // to its root, matching common tab-bar convention.
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
