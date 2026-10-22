import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_colors.dart';

/// WCAG 2.x contrast ratio.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const lightSurfaces = [AppColors.backgroundLight];
  const darkSurfaces = [
    AppColors.backgroundDark,
    AppColors.glassFallbackFillDark,
  ];

  // AUD-62 (and AUD-30's open follow-up): status icons and dots need 3:1
  // against every surface they sit on (WCAG 1.4.11).
  test('every status color reaches 3:1 on light and dark surfaces', () {
    const statuses = {
      'success': AppColors.buildSuccess,
      'failure': AppColors.buildFailure,
      'aborted': AppColors.buildAborted,
      'unstable': AppColors.buildUnstable,
      'running': AppColors.buildRunning,
      'paused': AppColors.buildPaused,
      'folder': AppColors.folder,
    };
    for (final MapEntry(key: name, value: color) in statuses.entries) {
      for (final surface in [...lightSurfaces, ...darkSurfaces]) {
        expect(
          _contrast(color, surface),
          greaterThanOrEqualTo(3.0),
          reason: '$name on $surface',
        );
      }
    }
  });

  test('job ball colors use the same measured shades', () {
    expect(AppColors.forJobColor('blue'), AppColors.buildSuccess);
    expect(AppColors.forJobColor('yellow_anime'), AppColors.buildUnstable);
    expect(AppColors.forJobColor('disabled'), AppColors.buildAborted);
  });

  test('success text reaches 4.5:1 in both themes', () {
    for (final surface in lightSurfaces) {
      expect(
        _contrast(AppColors.successText(Brightness.light), surface),
        greaterThanOrEqualTo(4.5),
      );
    }
    for (final surface in darkSurfaces) {
      expect(
        _contrast(AppColors.successText(Brightness.dark), surface),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}
