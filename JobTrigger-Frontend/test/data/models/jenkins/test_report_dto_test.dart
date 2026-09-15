import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/jenkins/test_report_dto.dart';

void main() {
  group('TestReportDto (US-PIPE-06)', () {
    test('parses pass/fail/skip counts', () {
      final dto = TestReportDto.fromJson({
        'passCount': 42,
        'failCount': 2,
        'skipCount': 1,
      });

      expect(dto.passCount, 42);
      expect(dto.failCount, 2);
      expect(dto.skipCount, 1);
      expect(dto.failingTests, isEmpty);
    });

    test('flattens FAILED and REGRESSION cases across suites to ClassName.testName', () {
      final dto = TestReportDto.fromJson({
        'passCount': 1,
        'failCount': 2,
        'skipCount': 0,
        'suites': [
          {
            'cases': [
              {
                'className': 'com.example.AuthTest',
                'name': 'testLogin',
                'status': 'FAILED',
              },
              {
                'className': 'com.example.AuthTest',
                'name': 'testLogout',
                'status': 'PASSED',
              },
            ],
          },
          {
            'cases': [
              {
                'className': 'com.example.JobTest',
                'name': 'testTrigger',
                'status': 'REGRESSION',
              },
            ],
          },
        ],
      });

      expect(dto.failingTests, [
        'com.example.AuthTest.testLogin',
        'com.example.JobTest.testTrigger',
      ]);
    });

    test('falls back to bare test name when className is absent', () {
      final dto = TestReportDto.fromJson({
        'suites': [
          {
            'cases': [
              {'name': 'testSomething', 'status': 'FAILED'},
            ],
          },
        ],
      });

      expect(dto.failingTests, ['testSomething']);
    });

    test('defaults to zero counts and empty failingTests when fields are absent', () {
      final dto = TestReportDto.fromJson(const {});

      expect(dto.passCount, 0);
      expect(dto.failCount, 0);
      expect(dto.skipCount, 0);
      expect(dto.failingTests, isEmpty);
    });

    test('toDomain() carries every field through unchanged', () {
      final dto = TestReportDto.fromJson({
        'passCount': 1,
        'failCount': 1,
        'skipCount': 1,
        'suites': [
          {
            'cases': [
              {
                'className': 'com.example.X',
                'name': 'y',
                'status': 'FAILED',
              },
            ],
          },
        ],
      });

      final domain = dto.toDomain();
      expect(domain.passCount, 1);
      expect(domain.failCount, 1);
      expect(domain.skipCount, 1);
      expect(domain.failingTests, ['com.example.X.y']);
    });
  });
}
