import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/tools/tool_catalog.dart';

/// Ported from `Tools/ToolSelection/CITool.swift`. Static — no notifier per
/// `docs/state-management.md`'s "Feature: tool_selection" section.
/// Icons are real brand marks via `simple_icons` — the old app's logo image
/// assets never actually existed (see `tasks/phase-0-setup.md` P0-08's
/// note), and generic Material icon fallbacks (gear, diamond, etc.) weren't
/// recognizable per-brand, so this swaps in the actual logos instead.
enum CiTool { jenkins, githubActions, gitlab, sonarqube, circleci }

extension CiToolX on CiTool {
  String get displayName => switch (this) {
    CiTool.jenkins => 'Jenkins',
    CiTool.githubActions => 'GitHub Actions',
    CiTool.gitlab => 'GitLab CI',
    CiTool.sonarqube => 'SonarQube',
    CiTool.circleci => 'CircleCI',
  };

  /// Short, one-line description shown under the tool name.
  String get tagline => switch (this) {
    CiTool.jenkins => 'Automate builds & pipelines',
    CiTool.githubActions => 'CI/CD built into GitHub',
    CiTool.gitlab => 'Pipelines for GitLab repos',
    CiTool.sonarqube => 'Code quality & security scans',
    CiTool.circleci => 'Fast, cloud-native pipelines',
  };

  IconData get icon => switch (this) {
    CiTool.jenkins => SimpleIcons.jenkins,
    CiTool.githubActions => SimpleIcons.githubactions,
    CiTool.gitlab => SimpleIcons.gitlab,
    CiTool.sonarqube => SimpleIcons.sonarqubeserver,
    CiTool.circleci => SimpleIcons.circleci,
  };

  Color get accentColor => switch (this) {
    CiTool.jenkins => AppColors.ciToolJenkins,
    CiTool.githubActions => AppColors.ciToolGithubActions,
    CiTool.gitlab => AppColors.ciToolGitlab,
    CiTool.sonarqube => AppColors.ciToolSonarqube,
    CiTool.circleci => AppColors.ciToolCircleci,
  };

  /// The id this tool has in `release/tools.json` (the enum name).
  String get manifestId => name;

  /// Tools with code in this app. GitLab CI and CircleCI are planned only:
  /// even a manifest that releases them can't make them selectable.
  bool get isImplemented =>
      this == CiTool.jenkins ||
      this == CiTool.githubActions ||
      this == CiTool.sonarqube;

  /// Built *and* released in this build's manifest. Everything that offers
  /// a tool (selection, Settings, deep links, the plan gates) asks this.
  bool get isAvailable =>
      isImplemented && ToolCatalog.current.isReleased(manifestId);

  /// The release it ships in, for the "Coming next" label (e.g. `1.1`).
  String? get releaseVersion => ToolCatalog.current.versionOf(manifestId);

  /// The two-letter mark on a "Coming next" tile.
  String get shortLabel => switch (this) {
    CiTool.jenkins => 'J',
    CiTool.githubActions => 'G',
    CiTool.gitlab => 'GL',
    CiTool.sonarqube => 'SQ',
    CiTool.circleci => 'CC',
  };
}

/// The tools shown as "Coming next": in the manifest, not released yet,
/// soonest release first.
List<CiTool> get comingNextTools => [
  for (final id in ToolCatalog.current.comingNext)
    ?CiTool.values.where((tool) => tool.name == id).firstOrNull,
];
