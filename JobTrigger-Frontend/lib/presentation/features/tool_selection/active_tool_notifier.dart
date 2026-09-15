import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'ci_tool.dart';

part 'active_tool_notifier.g.dart';

/// Which CI/CD tool's brand color tints `AppTheme`'s `primary`/`onPrimary`
/// (see `core/theme/app_theme.dart` and `main.dart`). `null` means "no tool
/// selected yet" — `Login`/`Signup`/`ToolSelectionScreen` render with the
/// original blue-and-white theme in that state; the app only turns
/// tool-colored once a card is actually tapped on `ToolSelectionScreen`.
///
/// Deliberately in-memory only, *not* persisted: an authenticated user is
/// always routed back through `ToolSelectionScreen` after a cold launch
/// (see `app_router.dart`'s redirect), so there's nothing to restore — and
/// persisting it previously meant a stale "jenkins" from an earlier session
/// made the pre-selection screens start red instead of blue, which is
/// exactly the bug this avoids.
@riverpod
class ActiveToolNotifier extends _$ActiveToolNotifier {
  @override
  CiTool? build() => null;

  void setActiveTool(CiTool tool) => state = tool;
}
