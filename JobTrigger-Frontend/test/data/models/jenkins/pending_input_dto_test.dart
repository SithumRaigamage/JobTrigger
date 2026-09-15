import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/jenkins/pending_input_dto.dart';

void main() {
  group('PendingInputDto (US-PIPE-05, unverified shape)', () {
    test('parses id/message/proceedText/abortText', () {
      final dto = PendingInputDto.fromJson({
        'id': 'Deploy to prod',
        'message': 'Approve deploy to production?',
        'proceedText': 'Ship it',
        'abortText': 'Cancel',
      });

      expect(dto.id, 'Deploy to prod');
      expect(dto.message, 'Approve deploy to production?');
      expect(dto.proceedText, 'Ship it');
      expect(dto.abortText, 'Cancel');
      expect(dto.inputs, isEmpty);
    });

    test('defaults proceedText/abortText/inputs when absent', () {
      final dto = PendingInputDto.fromJson({'id': 'x'});

      expect(dto.proceedText, 'Proceed');
      expect(dto.abortText, 'Abort');
      expect(dto.message, isNull);
      expect(dto.inputs, isEmpty);
    });

    test(
      'parses requested parameter definitions via the shared ParameterDefinitionDto shape',
      () {
        final dto = PendingInputDto.fromJson({
          'id': 'x',
          'inputs': [
            {
              'name': 'CONFIRM',
              'type': 'BooleanParameterDefinition',
              'defaultParameterValue': {'value': false},
            },
          ],
        });

        expect(dto.inputs, hasLength(1));
        expect(dto.inputs.single.name, 'CONFIRM');
        expect(dto.inputs.single.type, 'BooleanParameterDefinition');
      },
    );

    test('toDomain() carries every field through unchanged', () {
      final dto = PendingInputDto.fromJson({'id': 'x', 'message': 'Approve?'});

      final domain = dto.toDomain();
      expect(domain.id, 'x');
      expect(domain.message, 'Approve?');
      expect(domain.proceedText, 'Proceed');
      expect(domain.abortText, 'Abort');
    });
  });
}
