import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_colors.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/core/theme/app_tokens.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

/// P14-02: every colour pairing the redesign relies on, measured. Text
/// needs 4.5:1 (WCAG 1.4.3); dots, bars and icons need 3:1 (WCAG 1.4.11).
void main() {
  for (final (name, t) in const [
    ('dark', AppTokens.dark),
    ('light', AppTokens.light),
  ]) {
    group('$name tokens', () {
      test('each status reads as text on its own tint and on a card', () {
        for (final tone in StatusTone.values) {
          final s = t.status(tone);
          for (final ground in [s.background, t.card, t.background]) {
            expect(
              _contrast(s.foreground, ground),
              greaterThanOrEqualTo(4.5),
              reason: '$tone text on $ground',
            );
          }
        }
      });

      test('each status dot reaches 3:1 on a card and the background', () {
        for (final tone in StatusTone.values) {
          for (final ground in [t.card, t.background]) {
            expect(
              _contrast(t.status(tone).dot, ground),
              greaterThanOrEqualTo(3.0),
              reason: '$tone dot on $ground',
            );
          }
        }
      });

      test('muted and secondary text reach 4.5:1 on every surface', () {
        for (final color in [t.textMuted, t.textSecondary, t.text]) {
          for (final ground in [t.card, t.background, t.raised, t.chrome]) {
            expect(
              _contrast(color, ground),
              greaterThanOrEqualTo(4.5),
              reason: '$color on $ground',
            );
          }
        }
      });
    });
  }

  test('white on the accent reaches 4.5:1', () {
    expect(
      _contrast(Colors.white, AppColors.accent),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('both themes carry their tokens and the one accent', () {
    final light = AppTheme.light(), dark = AppTheme.dark();
    expect(light.extension<AppTokens>(), AppTokens.light);
    expect(dark.extension<AppTokens>(), AppTokens.dark);
    expect(light.colorScheme.primary, AppColors.accent);
    expect(dark.colorScheme.primary, AppColors.accent);
  });

  test('build results map to tones; a null result is still running', () {
    expect(AppColors.toneForBuildResult('SUCCESS'), StatusTone.success);
    expect(AppColors.toneForBuildResult('failure'), StatusTone.failure);
    expect(AppColors.toneForBuildResult('UNSTABLE'), StatusTone.unstable);
    expect(AppColors.toneForBuildResult(null), StatusTone.running);
    expect(AppColors.toneForBuildResult('ABORTED'), StatusTone.neutral);
  });

  test('stage statuses map to tones', () {
    expect(AppColors.toneForStageStatus('FAILED'), StatusTone.failure);
    expect(AppColors.toneForStageStatus('IN_PROGRESS'), StatusTone.running);
    expect(
      AppColors.toneForStageStatus('PAUSED_PENDING_INPUT'),
      StatusTone.paused,
    );
    expect(AppColors.toneForStageStatus('NOT_EXECUTED'), StatusTone.neutral);
  });

  test('job ball colors map to tones, "blue" meaning success', () {
    expect(AppColors.toneForJobColor('blue'), StatusTone.success);
    expect(AppColors.toneForJobColor('yellow_anime'), StatusTone.unstable);
    expect(AppColors.toneForJobColor('disabled'), StatusTone.neutral);
    expect(AppColors.isJobColorAnimating('red_anime'), isTrue);
  });

  // AUD-30: the build log's own colours, drawn on the console in both
  // themes, are tokens now — so they're measured like the rest.
  group('console', () {
    for (final (name, ground) in const [
      ('console', AppColors.consoleDark),
      ('an error line', AppColors.consoleErrorLine),
      ('a banner', AppColors.consoleBar),
    ]) {
      test('text reads at 4.5:1 on $name', () {
        expect(
          _contrast(AppColors.consoleText, ground),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
    test('line numbers read at 4.5:1 on the console and error lines', () {
      expect(
        _contrast(AppColors.consoleGutter, AppColors.consoleDark),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(AppColors.consoleGutter, AppColors.consoleErrorLine),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}
