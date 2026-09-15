import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/jenkins/job_property_dto.dart';

void main() {
  group('JobPropertyDto', () {
    test('parses nested parameterDefinitions', () {
      final dto = JobPropertyDto.fromJson({
        'parameterDefinitions': [
          {'name': 'BRANCH', 'type': 'StringParameterDefinition'},
          {'name': 'DEPLOY', 'type': 'BooleanParameterDefinition'},
        ],
      });

      expect(dto.parameterDefinitions, hasLength(2));
      expect(dto.parameterDefinitions!.first.name, 'BRANCH');
      expect(dto.parameterDefinitions!.last.name, 'DEPLOY');
    });

    test(
      'parameterDefinitions stays genuinely null (not []) when absent -- '
      'a property with no parameterDefinitions key is not a parameters holder',
      () {
        final dto = JobPropertyDto.fromJson(const {});

        expect(dto.parameterDefinitions, isNull);
      },
    );

    test('toDomain() maps each nested definition', () {
      final dto = JobPropertyDto.fromJson({
        'parameterDefinitions': [
          {'name': 'BRANCH', 'type': 'StringParameterDefinition'},
        ],
      });

      final domain = dto.toDomain();
      expect(domain.parameterDefinitions, hasLength(1));
      expect(domain.parameterDefinitions!.single.name, 'BRANCH');
    });

    test('toDomain() keeps parameterDefinitions null when absent', () {
      final dto = JobPropertyDto.fromJson(const {});

      expect(dto.toDomain().parameterDefinitions, isNull);
    });
  });
}
