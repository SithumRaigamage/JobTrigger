import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

/// Jenkins' pipeline stage/step `status` vocabulary (`FAILED`,
/// `IN_PROGRESS`, `PAUSED_PENDING_INPUT`, …) differs from a build's classic
/// `result` (`FAILURE`, …); [AppColors.toneForStageStatus] maps it. This is
/// the stage's dot/icon colour in the current theme. Always paired with an
/// icon shape and text (NFR-A11Y-03).
Color colorForStageStatus(BuildContext context, String status) =>
    AppTokens.of(context).status(AppColors.toneForStageStatus(status)).dot;

IconData iconForStageStatus(String status) => switch (status.toUpperCase()) {
  'SUCCESS' => Icons.check_circle,
  'FAILED' => Icons.cancel,
  'IN_PROGRESS' => Icons.autorenew,
  'PAUSED_PENDING_INPUT' => Icons.pause_circle,
  'NOT_EXECUTED' => Icons.circle_outlined,
  _ => Icons.circle,
};

/// The stage's status in words, for screen readers and labels.
String labelForStageStatus(String status) => switch (status.toUpperCase()) {
  'SUCCESS' => 'Passed',
  'FAILED' => 'Failed',
  'UNSTABLE' => 'Unstable',
  'IN_PROGRESS' => 'Running',
  'PAUSED_PENDING_INPUT' => 'Waiting for input',
  'NOT_EXECUTED' => 'Not run',
  'ABORTED' => 'Aborted',
  _ => 'Unknown',
};
