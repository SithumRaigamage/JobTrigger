import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/build_trends.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';

JenkinsBuild _build(
  int n,
  String? result,
  double duration, {
  bool building = false,
}) => JenkinsBuild(
  number: n,
  url: 'u$n',
  result: result,
  duration: duration,
  timestamp: 0,
  building: building,
);

void main() {
  test('too few finished builds gives no trends', () {
    expect(
      buildTrends([
        _build(5, null, 0, building: true),
        for (var i = 4; i >= 1; i--) _build(i, 'SUCCESS', 1000),
      ]),
      isNull,
    );
  });

  test('success rate, average, p90, and oldest-first points (US-JX-15)', () {
    // Newest first, as history returns them. One still running (ignored).
    final builds = [
      _build(11, null, 0, building: true),
      for (var i = 10; i >= 1; i--)
        _build(i, i.isEven ? 'SUCCESS' : 'FAILURE', i * 1000.0),
    ];

    final trends = buildTrends(builds)!;

    expect(trends.sampleSize, 10);
    expect(trends.successRate, 0.5);
    expect(trends.averageMillis, 5500);
    expect(trends.p90Millis, 9000);
    expect(trends.points.first.number, 1);
    expect(trends.points.last.number, 10);
    expect(trends.points.first.failed, isTrue);
  });

  test('the window limits the sample to the newest builds', () {
    final builds = [for (var i = 60; i >= 1; i--) _build(i, 'SUCCESS', 1000)];
    expect(buildTrends(builds)!.sampleSize, 20);
    expect(buildTrends(builds, window: 50)!.sampleSize, 50);
  });

  test('UNSTABLE does not count as success', () {
    final builds = [for (var i = 5; i >= 1; i--) _build(i, 'UNSTABLE', 1)];
    expect(buildTrends(builds)!.successRate, 0);
  });
}
