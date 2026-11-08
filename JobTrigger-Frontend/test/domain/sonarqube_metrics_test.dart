import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_metrics.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';

void main() {
  group('formatSonarQubeValue', () {
    test('percentages keep at most one decimal and a % sign', () {
      expect(formatSonarQubeValue('coverage', '62.14'), '62.1%');
      expect(formatSonarQubeValue('coverage', '80.0'), '80%');
      expect(formatSonarQubeValue('duplicated_lines_density', '3.0'), '3%');
      expect(formatSonarQubeValue('new_coverage', '0.0'), '0%');
    });

    test('counts get thousands separators', () {
      expect(formatSonarQubeValue('ncloc', '123456'), '123,456');
      expect(formatSonarQubeValue('bugs', '7'), '7');
      expect(formatSonarQubeValue('code_smells', '1000'), '1,000');
    });

    test('ratings are letters', () {
      expect(formatSonarQubeValue('reliability_rating', '1.0'), 'A');
      expect(formatSonarQubeValue('security_rating', '5.0'), 'E');
      expect(formatSonarQubeValue('sqale_rating', '9.0'), '9.0');
    });

    test('a missing value is a dash, never a zero', () {
      expect(formatSonarQubeValue('coverage', null), '—');
      expect(formatSonarQubeValue('bugs', ''), '—');
    });

    test('a value that is not a number is shown as sent', () {
      expect(formatSonarQubeValue('anything', 'OK'), 'OK');
    });
  });

  group('sonarQubeMetricLabel', () {
    test('known keys have names; unknown ones are made readable', () {
      expect(sonarQubeMetricLabel('new_coverage'), 'Coverage on new code');
      expect(sonarQubeMetricLabel('duplicated_lines_density'), 'Duplication');
      expect(sonarQubeMetricLabel('new_lines_to_cover'), 'New lines to cover');
    });
  });

  group('QualityGateState / conditions', () {
    test('parses SonarQube statuses; unknown means no verdict', () {
      expect(QualityGateState.parse('OK'), QualityGateState.passed);
      expect(QualityGateState.parse('WARN'), QualityGateState.warning);
      expect(QualityGateState.parse('ERROR'), QualityGateState.failed);
      expect(QualityGateState.parse('NONE'), QualityGateState.none);
      expect(QualityGateState.parse('SOMETHING_NEW'), QualityGateState.none);
      expect(QualityGateState.parse(null), QualityGateState.none);
    });

    test('failing keeps only the broken conditions, in words', () {
      const gate = SonarQubeQualityGate(
        state: QualityGateState.failed,
        conditions: [
          QualityGateCondition(
            metricKey: 'new_coverage',
            comparator: 'LT',
            threshold: '80',
            actual: '62.1',
            failed: true,
          ),
          QualityGateCondition(
            metricKey: 'new_bugs',
            comparator: 'GT',
            threshold: '0',
            actual: '0',
            failed: false,
          ),
        ],
      );
      expect(gate.failing.map((c) => c.metricKey), ['new_coverage']);
      expect(gate.failing.single.failsWhen, 'below');
      expect(gate.conditions.last.failsWhen, 'above');
    });
  });
}
