import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../core/analytics/analytics_service.dart';
import 'ci_tool.dart';

part 'active_tool_notifier.g.dart';

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

  void setActiveTool(CiTool tool) {
    state = tool;
    // P20-76: which tools people use decides what's built next. Anonymous,
    // fire-and-forget; a no-op when analytics isn't configured.
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .track(AnalyticsEvent.toolSelected, {'tool': tool.name}),
    );
  }
}
