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

  group('JenkinsBuildDto.upstreamCause (US-PIPE-09)', () {
    test('extracts upstreamProject/upstreamUrl from an UpstreamCause entry', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'actions': [
          {
            'causes': [
              {
                'shortDescription': 'Started by upstream project "foo" build number 3',
                'upstreamProject': 'foo',
                'upstreamUrl': 'https://jenkins.test/job/foo/',
              },
            ],
          },
        ],
      });

      // causes (US-PIPE-02) still parses the flat description text too --
      // the two fields are independent, both sourced from `actions`.
      expect(dto.causes, [
        'Started by upstream project "foo" build number 3',
      ]);
      expect(dto.upstreamCause?.projectName, 'foo');
      expect(dto.upstreamCause?.url, 'https://jenkins.test/job/foo/');
    });

    test('is null when the cause has no upstreamProject/upstreamUrl (e.g. a user cause)', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'actions': [
          {
            'causes': [
              {'shortDescription': 'Started by user Jane Doe'},
            ],
          },
        ],
      });

      expect(dto.upstreamCause, isNull);
    });

    test('is null when actions is absent', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
      });

      expect(dto.upstreamCause, isNull);
    });

    test('toDomain() carries upstreamCause through unchanged', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'actions': [
          {
            'causes': [
              {
                'upstreamProject': 'foo',
                'upstreamUrl': 'https://jenkins.test/job/foo/',
              },
            ],
          },
        ],
      });

      expect(dto.toDomain().upstreamCause?.projectName, 'foo');
    });
  });

  group('JenkinsBuildDto.parameterValues (US-PIPE-08)', () {
    test('flattens ParametersAction entries to a name->value map', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'actions': [
          {
            'parameters': [
              {'name': 'BRANCH', 'value': 'main'},
              {'name': 'DEPLOY', 'value': true},
            ],
          },
        ],
      });

      expect(dto.parameterValues, {'BRANCH': 'main', 'DEPLOY': 'true'});
    });

    test('coexists with causes/upstreamCause on the same actions array', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'actions': [
          {
            'causes': [
              {'shortDescription': 'Started by user Jane Doe'},
            ],
          },
          {
            'parameters': [
              {'name': 'BRANCH', 'value': 'main'},
            ],
          },
        ],
      });

      expect(dto.causes, ['Started by user Jane Doe']);
      expect(dto.parameterValues, {'BRANCH': 'main'});
    });

    test('defaults to an empty map when actions is absent', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
      });

      expect(dto.parameterValues, isEmpty);
    });

    test('toDomain() carries parameterValues through unchanged', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'actions': [
          {
            'parameters': [
              {'name': 'BRANCH', 'value': 'main'},
            ],
          },
        ],
      });

      expect(dto.toDomain().parameterValues, {'BRANCH': 'main'});
    });
  });

  group('JenkinsBuildDto.changes (US-PIPE-03)', () {
    test('flattens changeSet.items to author + message', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'changeSet': {
          'kind': 'git',
          'items': [
            {
              'msg': 'Fix null check in trigger flow',
              'author': {'fullName': 'Jane Doe'},
            },
            {
              'msg': 'Bump dio to 5.x',
              'author': {'fullName': 'John Smith'},
            },
          ],
        },
      });

      expect(dto.changes, hasLength(2));
      expect(dto.changes[0].author, 'Jane Doe');
      expect(dto.changes[0].message, 'Fix null check in trigger flow');
      expect(dto.changes[1].author, 'John Smith');
    });

    test('defaults to an empty list when changeSet is absent', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
      });

      expect(dto.changes, isEmpty);
    });

    test('defaults to an empty list when changeSet.items is empty', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'changeSet': {'kind': 'git', 'items': <dynamic>[]},
      });

      expect(dto.changes, isEmpty);
    });

    test(
      'skips a malformed item (missing msg or author.fullName) rather than throwing',
      () {
        final dto = JenkinsBuildDto.fromJson({
          'number': 12,
          'url': 'https://jenkins.test/job/x/12/',
          'timestamp': 1700000000000.0,
          'changeSet': {
            'items': [
              {'msg': 'no author here'},
              {
                'msg': 'well-formed',
                'author': {'fullName': 'Jane Doe'},
              },
            ],
          },
        });

        expect(dto.changes, hasLength(1));
        expect(dto.changes.single.message, 'well-formed');
      },
    );

    test('toDomain() carries changes through unchanged', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'changeSet': {
          'items': [
            {
              'msg': 'Fix null check',
              'author': {'fullName': 'Jane Doe'},
            },
          ],
        },
      });

      expect(dto.toDomain().changes.single.author, 'Jane Doe');
    });
  });

  group('JenkinsBuildDto.artifacts (US-PIPE-07)', () {
    test('parses a flat, non-polymorphic artifacts array', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'artifacts': [
          {'fileName': 'app.apk', 'relativePath': 'build/app.apk'},
          {'fileName': 'report.html', 'relativePath': 'report.html'},
        ],
      });

      expect(dto.artifacts, hasLength(2));
      expect(dto.artifacts[0].fileName, 'app.apk');
      expect(dto.artifacts[0].relativePath, 'build/app.apk');
    });

    test('defaults to an empty list when artifacts is absent', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
      });

      expect(dto.artifacts, isEmpty);
    });

    test('toDomain() maps each artifact through unchanged', () {
      final dto = JenkinsBuildDto.fromJson({
        'number': 12,
        'url': 'https://jenkins.test/job/x/12/',
        'timestamp': 1700000000000.0,
        'artifacts': [
          {'fileName': 'app.apk', 'relativePath': 'build/app.apk'},
        ],
      });

      final artifact = dto.toDomain().artifacts.single;
      expect(artifact.fileName, 'app.apk');
      expect(artifact.relativePath, 'build/app.apk');
    });
  });
}
