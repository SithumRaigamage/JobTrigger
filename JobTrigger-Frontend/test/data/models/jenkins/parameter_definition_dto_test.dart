import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/jenkins/parameter_definition_dto.dart';

void main() {
  group('ParameterDefinitionDto', () {
    // Jenkins' real key is `defaultParameterValue`, nested as
    // `{"name": ..., "value": <default>}` -- not a bare `defaultValue`, per
    // this DTO's own doc comment calling out `docs/data-models.md`'s
    // sample as wrong. This is exactly the risk `_defaultValueFromJson`
    // exists to unwrap, so it's worth pinning down explicitly.
    test(
      'unwraps defaultParameterValue.value into defaultValue (string type)',
      () {
        final dto = ParameterDefinitionDto.fromJson({
          'name': 'BRANCH',
          'type': 'StringParameterDefinition',
          'description': 'Branch to build',
          'defaultParameterValue': {'name': 'BRANCH', 'value': 'main'},
        });

        expect(dto.name, 'BRANCH');
        expect(dto.type, 'StringParameterDefinition');
        expect(dto.description, 'Branch to build');
        expect(dto.defaultValue, 'main');
      },
    );

    test('unwraps a boolean defaultParameterValue', () {
      final dto = ParameterDefinitionDto.fromJson({
        'name': 'DEPLOY',
        'type': 'BooleanParameterDefinition',
        'defaultParameterValue': {'name': 'DEPLOY', 'value': false},
      });

      expect(dto.defaultValue, false);
    });

    test('parses choices for a choice parameter', () {
      final dto = ParameterDefinitionDto.fromJson({
        'name': 'ENVIRONMENT',
        'type': 'ChoiceParameterDefinition',
        'choices': ['dev', 'staging', 'prod'],
      });

      expect(dto.choices, ['dev', 'staging', 'prod']);
    });

    test(
      'leaves description/choices/defaultValue null when absent',
      () {
        final dto = ParameterDefinitionDto.fromJson({
          'name': 'BRANCH',
          'type': 'StringParameterDefinition',
        });

        expect(dto.description, isNull);
        expect(dto.choices, isNull);
        expect(dto.defaultValue, isNull);
      },
    );

    test('toDomain() carries every field through unchanged', () {
      final dto = ParameterDefinitionDto.fromJson({
        'name': 'BRANCH',
        'type': 'StringParameterDefinition',
        'description': 'Branch to build',
        'choices': ['main', 'develop'],
        'defaultParameterValue': {'value': 'main'},
      });

      final domain = dto.toDomain();
      expect(domain.name, 'BRANCH');
      expect(domain.type, 'StringParameterDefinition');
      expect(domain.description, 'Branch to build');
      expect(domain.choices, ['main', 'develop']);
      expect(domain.defaultValue, 'main');
    });
  });
}
