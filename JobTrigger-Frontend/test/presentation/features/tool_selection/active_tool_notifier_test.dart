import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/features/tool_selection/active_tool_notifier.dart';
import 'package:job_trigger/presentation/features/tool_selection/ci_tool.dart';

void main() {
  test('initial state is null -- no tool selected yet', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(activeToolNotifierProvider), isNull);
  });

  test('setActiveTool updates the state to the given tool', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(activeToolNotifierProvider.notifier)
        .setActiveTool(CiTool.githubActions);

    expect(container.read(activeToolNotifierProvider), CiTool.githubActions);
  });

  // Regression: the choice is made on ToolSelectionScreen, which only reads
  // the provider, and the screens that watch it build on a later frame.
  // Auto-disposed, the state was gone by then, so a switch to GitHub
  // Actions fell back to Jenkins everywhere (found with Playwright after
  // P14-02 removed the theme's watch that had kept it alive).
  test('the choice survives with nothing watching it', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(activeToolNotifierProvider.notifier)
        .setActiveTool(CiTool.githubActions);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(activeToolNotifierProvider), CiTool.githubActions);
  });
}
