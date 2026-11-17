import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/onboarding/first_run_steps.dart';

void main() {
  test('reports how many steps are done', () {
    expect(
      const FirstRunSteps(
        connected: false,
        triggered: false,
        alerts: false,
      ).doneCount,
      0,
    );
    expect(
      const FirstRunSteps(
        connected: true,
        triggered: false,
        alerts: false,
      ).doneCount,
      1,
    );
    expect(
      const FirstRunSteps(
        connected: true,
        triggered: true,
        alerts: false,
      ).doneCount,
      2,
    );
  });

  test('is only all done with every step', () {
    expect(
      const FirstRunSteps(
        connected: true,
        triggered: true,
        alerts: false,
      ).allDone,
      isFalse,
    );
    expect(
      const FirstRunSteps(
        connected: true,
        triggered: true,
        alerts: true,
      ).allDone,
      isTrue,
    );
  });
}
