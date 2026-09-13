import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Ported from `Tools/ToolSelection/CITool.swift`. Static — no notifier per
/// `docs/state-management.md`'s "Feature: tool_selection" section, unless a
/// tool beyond Jenkins becomes real (out of scope, see `tasks/backlog.md`).
/// The old app's logo image assets never actually existed (see
/// `tasks/phase-0-setup.md` P0-08's note), so this only ports the fallback
/// SF Symbol + accent-color path, which is what really rendered.
enum CiTool { jenkins, githubActions, gitlab, sonarqube, circleci }

extension CiToolX on CiTool {
  String get displayName => switch (this) {
    CiTool.jenkins => 'Jenkins',
    CiTool.githubActions => 'GitHub Actions',
    CiTool.gitlab => 'GitLab CI',
    CiTool.sonarqube => 'SonarQube',
    CiTool.circleci => 'CircleCI',
  };

  IconData get icon => switch (this) {
    CiTool.jenkins => Icons.settings,
    CiTool.githubActions => Icons.account_tree,
    CiTool.gitlab => Icons.diamond,
    CiTool.sonarqube => Icons.monitor_heart,
    CiTool.circleci => Icons.autorenew,
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
