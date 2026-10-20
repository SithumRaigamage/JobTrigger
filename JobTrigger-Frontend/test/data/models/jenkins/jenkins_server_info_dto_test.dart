import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/jenkins/jenkins_server_info_dto.dart';

void main() {
  group('JenkinsServerInfoDto', () {
    test('parses the root /api/json fields and nested jobs', () {
      final dto = JenkinsServerInfoDto.fromJson({
        'mode': 'NORMAL',
        'nodeDescription': 'the master Jenkins node',
        'numExecutors': 4,
        'useSecurity': true,
        'jobs': [
          {'name': 'demo', 'url': 'https://jenkins.test/job/demo/'},
        ],
      });

      expect(dto.mode, 'NORMAL');
      expect(dto.nodeDescription, 'the master Jenkins node');
      expect(dto.numExecutors, 4);
      expect(dto.useSecurity, isTrue);
      expect(dto.jobs, hasLength(1));
      expect(dto.jobs.single.name, 'demo');
    });

    test('defaults jobs to an empty list and every other field to null', () {
      final dto = JenkinsServerInfoDto.fromJson(const {});

      expect(dto.jobs, isEmpty);
      expect(dto.mode, isNull);
      expect(dto.nodeDescription, isNull);
      expect(dto.numExecutors, isNull);
      expect(dto.useSecurity, isNull);
    });
  });
}
