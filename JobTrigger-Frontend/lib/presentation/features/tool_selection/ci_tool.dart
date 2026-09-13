import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../../core/theme/app_colors.dart';

/// Ported from `Tools/ToolSelection/CITool.swift`. Static — no notifier per
/// `docs/state-management.md`'s "Feature: tool_selection" section, unless a
/// tool beyond Jenkins becomes real (out of scope, see `tasks/backlog.md`).
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

  /// Only Jenkins is available in v1.0 — the rest stay disabled placeholders
  /// (see `tasks/backlog.md`).
  bool get isAvailable => this == CiTool.jenkins;
}
