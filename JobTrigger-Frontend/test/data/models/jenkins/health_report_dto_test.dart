import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/jenkins/health_report_dto.dart';

void main() {
  group('HealthReportDto', () {
    test('parses description/iconClassName/score', () {
      final dto = HealthReportDto.fromJson({
        'description': 'Build stability: 3 out of the last 5 builds failed.',
        'iconClassName': 'icon-health-40to59',
        'score': 40,
      });

      expect(
        dto.description,
        'Build stability: 3 out of the last 5 builds failed.',
      );
      expect(dto.iconClassName, 'icon-health-40to59');
      expect(dto.score, 40);
    });

    test('defaults every field to null when absent', () {
      final dto = HealthReportDto.fromJson(const {});

      expect(dto.description, isNull);
      expect(dto.iconClassName, isNull);
      expect(dto.score, isNull);
    });

    test('toDomain() carries every field through unchanged', () {
      final dto = HealthReportDto.fromJson({
        'description': 'Build stability',
        'iconClassName': 'icon-health-80plus',
        'score': 90,
      });

      final domain = dto.toDomain();
      expect(domain.description, 'Build stability');
      expect(domain.iconClassName, 'icon-health-80plus');
      expect(domain.score, 90);
    });
  });
}
