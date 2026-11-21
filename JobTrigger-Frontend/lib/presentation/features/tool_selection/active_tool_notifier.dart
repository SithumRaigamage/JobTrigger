import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../subscription/plan_gate.dart';
import 'ci_tool.dart';

part 'active_tool_notifier.g.dart';

/// The `shared_preferences` key of the last chosen tool (US-TOOL-01).
const activeToolKey = 'active_tool';

/// Which CI/CD tool the session is using: it picks what the Home and
/// History tabs show and which credentials Settings and Profile manage.
/// `null` means "no tool selected yet"; screens treat it as Jenkins.
///
/// Deliberately in-memory only, *not* persisted: an authenticated user is
/// always routed back through `ToolSelectionScreen` after a cold launch
/// (see `app_router.dart`'s redirect), so there's nothing to restore.
///
/// Kept alive for the session: the choice is made on
/// `ToolSelectionScreen`, which only reads this, and the screens that watch
/// it build a frame later. Auto-disposed, the state was dropped in between
/// and a switch to GitHub Actions silently fell back to Jenkins — hidden
/// until P14-02 removed the theme's app-wide watch that kept it alive.
@Riverpod(keepAlive: true)
class ActiveToolNotifier extends _$ActiveToolNotifier {
  @override
  CiTool? build() => null;

  /// Ignores a tool this build doesn't offer (not released, or no code), so
  /// nothing can select one however it asks.
  void setActiveTool(CiTool tool) {
    if (!tool.isAvailable) return;
    state = tool;
    // US-TOOL-01 (owner decision 2026-11-21): remembered so a returning
    // user skips tool selection; user-scoped, cleared on logout.
    unawaited(_remember(tool));
  }

  /// Best effort: an unavailable store only means the picker shows again.
  static Future<void> _remember(CiTool tool) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(activeToolKey, tool.name);
    } on Object {
      // Nothing to do.
    }
  }

  /// P20-25: the paywall reason when [tool] needs Pro for this user (they
  /// use another tool and the plan has no `multiTool`), else null.
  Future<String?> blockedReason(CiTool tool) async {
    // Billing off: nothing is read or fetched.
    if (ref.read(planGateProvider).multiTool == null) return null;
    final locked = await ref.read(proLockedToolsProvider.future);
    return locked.contains(tool) ? 'multiTool' : null;
  }
}
