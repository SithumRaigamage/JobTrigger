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
}
