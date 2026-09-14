import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/jenkins/jenkins_build_dto.dart';

void main() {
  group('JenkinsBuildDto.causes (US-PIPE-02)', () {
    test('flattens shortDescription out of a CauseAction entry', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'actions': [
          {
            '_class': 'hudson.model.CauseAction',
            'causes': [
              {'shortDescription': 'Started by user Jane Doe'},
            ],
          },
        ],
      });

      expect(dto.causes, ['Started by user Jane Doe']);
    });

    test('flattens multiple causes across multiple action entries', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'actions': [
          {
            'causes': [
              {'shortDescription': 'Started by upstream project "foo"'},
            ],
          },
          // Other action types Jenkins returns alongside CauseAction
          // (parameters, environment, etc.) never carry a "causes" key.
          {'_class': 'hudson.model.ParametersAction'},
          {
            'causes': [
              {'shortDescription': 'Started by timer'},
            ],
          },
        ],
      });

      expect(dto.causes, [
        'Started by upstream project "foo"',
        'Started by timer',
      ]);
    });

    test('defaults to an empty list when actions is absent', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
      });

      expect(dto.causes, isEmpty);
    });

    test('defaults to an empty list when no action carries causes', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'actions': [
          {'_class': 'hudson.model.ParametersAction'},
          <String, dynamic>{},
        ],
      });

      expect(dto.causes, isEmpty);
    });

    test('toDomain() carries causes through unchanged', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'actions': [
          {
            'causes': [
              {'shortDescription': 'Started by an SCM change'},
            ],
          },
        ],
      });

      expect(dto.toDomain().causes, ['Started by an SCM change']);
    });
  });
}
