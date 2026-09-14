import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../common_widgets/glass_surface.dart';

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
        // Lets branch content scroll up underneath the glass nav bar below
        // instead of stopping at its top edge — without this there'd be
        // nothing behind the bar for its BackdropFilter to blur (US-DESIGN-
        // 01/04). Each branch screen adds matching bottom padding to its
        // scrollable so the last item isn't hidden behind the bar.
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: GlassSurface.chrome(
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
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
      ),
    );
  }
}

/// Height to reserve at the bottom of each tab branch's scrollable content
/// so its last item clears the floating glass nav bar (`extendBody: true`
/// above means the branch's own `Scaffold` no longer reserves this space
/// automatically). Matches `NavigationBar`'s default height; screens with a
/// taller device inset (e.g. gesture nav) still get that via `SafeArea`
/// around their own content, this only accounts for the bar itself.
const kGlassNavBarHeight = 80.0;
