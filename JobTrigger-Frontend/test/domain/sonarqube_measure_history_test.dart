import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_measure_history.dart';

SonarQubeMeasurePoint _p(int day, num value) =>
    SonarQubeMeasurePoint(date: DateTime(2026, 11, day), value: value);

SonarQubeMeasureHistory _history(List<SonarQubeMeasurePoint> points) =>
    SonarQubeMeasureHistory(metric: 'coverage', unit: '%', points: points);

void main() {
  group('measure history (US-SQ-QUALITY-11)', () {
    test('one point is not a trend', () {
      expect(_history([_p(1, 60)]).hasEnoughHistory, isFalse);
      expect(_history(const []).hasEnoughHistory, isFalse);
      expect(_history([_p(1, 60), _p(2, 61)]).hasEnoughHistory, isTrue);
    });

    test(
      'lowest, highest and latest are the extremes, ties keep the first',
      () {
        final history = _history([
          _p(1, 71),
          _p(2, 69.2),
          _p(3, 77.8),
          _p(4, 69.2),
        ]);

        expect(history.lowest!.value, 69.2);
        expect(history.lowest!.date.day, 2);
        expect(history.highest!.value, 77.8);
        expect(history.latest!.value, 69.2);
        expect(history.format(69.2), '69.2%');
        expect(history.format(77), '77%');
      },
    );

    test('a tap selects the nearest point', () {
      final points = [_p(1, 1), _p(2, 2), _p(3, 3), _p(4, 4), _p(5, 5)];

      expect(nearestSonarQubePointIndex(points, 0, 400), 0);
      expect(nearestSonarQubePointIndex(points, 400, 400), 4);
      expect(nearestSonarQubePointIndex(points, 210, 400), 2);
      expect(nearestSonarQubePointIndex(points, 151, 400), 2);
      // Degenerate input never throws.
      expect(nearestSonarQubePointIndex(points, 10, 0), 0);
      expect(nearestSonarQubePointIndex(const [], 10, 100), 0);
    });
  });
}
