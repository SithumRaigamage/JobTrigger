import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/build_progress.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';

JenkinsBuild _build({required double timestamp, double? estimatedDuration}) =>
    JenkinsBuild(
      number: 1,
      url: 'https://jenkins.test/job/x/1/',
      timestamp: timestamp,
      estimatedDuration: estimatedDuration,
      building: true,
    );

void main() {
  final now = DateTime.utc(2026, 1, 1, 12);
  final nowMillis = now.millisecondsSinceEpoch.toDouble();

  test('returns 0 at the very start of a build', () {
    final build = _build(timestamp: nowMillis, estimatedDuration: 60000);
    expect(BuildProgress.ratioFor(build, now: now), 0.0);
  });

  test('returns 0.5 halfway through the estimated duration', () {
    final build = _build(
      timestamp: nowMillis - 30000,
      estimatedDuration: 60000,
    );
    expect(BuildProgress.ratioFor(build, now: now), closeTo(0.5, 0.0001));
  });

  test('clamps to 1.0 once past the estimated duration', () {
    final build = _build(
      timestamp: nowMillis - 120000,
      estimatedDuration: 60000,
    );
    expect(BuildProgress.ratioFor(build, now: now), 1.0);
  });

  test('returns 0 when estimatedDuration is null', () {
    final build = _build(timestamp: nowMillis - 30000, estimatedDuration: null);
    expect(BuildProgress.ratioFor(build, now: now), 0.0);
  });

  test('returns 0 when estimatedDuration is zero or negative', () {
    final build = _build(timestamp: nowMillis - 30000, estimatedDuration: 0);
    expect(BuildProgress.ratioFor(build, now: now), 0.0);
  });
}
