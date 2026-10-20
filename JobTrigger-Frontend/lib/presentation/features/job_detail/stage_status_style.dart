import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Jenkins' pipeline stage/step `status` vocabulary (`FAILED`,
/// `IN_PROGRESS`, `PAUSED_PENDING_INPUT`, …) differs from a build's classic
/// `result` (`FAILURE`, …), so it can't reuse `AppColors.forBuildResult`.
/// Always paired with an icon shape and text (NFR-A11Y-03).
Color colorForStageStatus(String status) => switch (status.toUpperCase()) {
  'SUCCESS' => AppColors.buildSuccess,
  'FAILED' => AppColors.buildFailure,
  'UNSTABLE' => AppColors.buildUnstable,
  'IN_PROGRESS' => AppColors.buildRunning,
  'PAUSED_PENDING_INPUT' => AppColors.buildPaused,
  _ => AppColors.buildAborted, // NOT_EXECUTED, ABORTED, unrecognized.
};

IconData iconForStageStatus(String status) => switch (status.toUpperCase()) {
  'SUCCESS' => Icons.check_circle,
  'FAILED' => Icons.cancel,
  'IN_PROGRESS' => Icons.autorenew,
  'PAUSED_PENDING_INPUT' => Icons.pause_circle,
  'NOT_EXECUTED' => Icons.circle_outlined,
  _ => Icons.circle,
};
