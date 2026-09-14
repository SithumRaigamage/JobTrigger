import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/jenkins/pipeline_stage_dto.dart';

void main() {
  group('PipelineDescribeDto (US-PIPE-04)', () {
    test('parses stages in order', () {
      final dto = PipelineDescribeDto.fromJson({
        'stages': [
          {
            'id': '6',
            'name': 'Build',
            'status': 'SUCCESS',
            'durationMillis': 4200,
          },
          {'id': '9', 'name': 'Deploy', 'status': 'IN_PROGRESS'},
        ],
      });

      expect(dto.stages, hasLength(2));
      expect(dto.stages[0].name, 'Build');
      expect(dto.stages[0].status, 'SUCCESS');
      expect(dto.stages[0].durationMillis, 4200);
      expect(dto.stages[1].name, 'Deploy');
      expect(dto.stages[1].durationMillis, isNull);
    });

    test('defaults to an empty list when stages is absent', () {
      final dto = PipelineDescribeDto.fromJson(const {});

      expect(dto.stages, isEmpty);
    });

    test('toDomain() carries every stage through unchanged', () {
      final dto = PipelineDescribeDto.fromJson({
        'stages': [
          {'id': '6', 'name': 'Build', 'status': 'FAILED'},
        ],
      });

      final stages = dto.toDomain();
      expect(stages.single.id, '6');
      expect(stages.single.name, 'Build');
      expect(stages.single.status, 'FAILED');
    });
  });
}
