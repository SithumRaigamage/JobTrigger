import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/credentials_repository_impl.dart';
import '../../../data/repositories/github_credentials_repository_impl.dart';
import '../../../data/repositories/sonarqube_credentials_repository_impl.dart';
import 'active_tool_notifier.dart';
import 'ci_tool.dart';

part 'returning_tool_provider.g.dart';

/// US-TOOL-01 (owner decision 2026-11-21): the tool a returning user goes
/// straight to, or null to show tool selection. A returning user is one
/// with at least one saved credential, of any tool. The tool chosen last
/// wins if it still has one (or if the lists can't be read); otherwise the
/// first tool, in the picker's order, that has one. A tool the plan locks
/// (P20-25) is never picked.
@riverpod
Future<CiTool?> returningTool(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final savedName = prefs.getString(activeToolKey);
  final saved = CiTool.values.where((t) => t.name == savedName).firstOrNull;

  Future<bool?> hasSaved(CiTool tool) async {
    final result = switch (tool) {
      CiTool.jenkins =>
        await ref.read(credentialsRepositoryProvider).fetchAll(),
      CiTool.githubActions =>
        await ref.read(gitHubCredentialsRepositoryProvider).fetchAll(),
      CiTool.sonarqube =>
        await ref.read(sonarQubeCredentialsRepositoryProvider).fetchAll(),
      _ => null,
    };
    return switch (result) {
      Ok(:final value) => value.isNotEmpty,
      _ => null, // unknown: the list couldn't be read
    };
  }

  final tools = CiTool.values.where((t) => t.isAvailable).toList();
  final known = {for (final tool in tools) tool: await hasSaved(tool)};
  final unreadable = known.values.every((v) => v == null);
  final candidates = [
    if (saved != null && saved.isAvailable && (known[saved] ?? unreadable))
      saved,
    for (final tool in tools)
      if (known[tool] ?? false) tool,
  ];
  final notifier = ref.read(activeToolNotifierProvider.notifier);
  for (final tool in candidates) {
    if (await notifier.blockedReason(tool) == null) return tool;
  }
  return null;
}
