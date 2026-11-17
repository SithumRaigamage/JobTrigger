import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/jenkins/pending_input_dto.dart';

void main() {
  group('PendingInputDto (US-PIPE-05, verified P11-02)', () {
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

    test('parses the real payload recorded from a paused pipeline', () {
      final raw =
          jsonDecode(
                File(
                  'test/fixtures/jenkins_pending_input_params.json',
                ).readAsStringSync(),
              )
              as List<dynamic>;

      final input = PendingInputDto.fromJson(
        raw.single as Map<String, dynamic>,
      ).toDomain();

      expect(input.id, 'DeployGate');
      expect(input.message, 'Deploy to production?');
      expect(input.proceedText, 'Deploy');
      // Jenkins sends no abortText.
      expect(input.abortText, 'Abort');
      expect(input.inputs.map((p) => p.name), ['VERSION', 'REGION', 'OTP']);
      expect(input.inputs[0].defaultValue, '1.2.3');
      // Nested under `definition` -- the shape P7-07 got wrong.
      expect(input.inputs[1].choices, ['eu-west-1', 'us-east-1']);
      expect(input.inputs[1].defaultValue, 'eu-west-1');
      expect(input.inputs[2].type, 'PasswordParameterDefinition');
    });

    test('tolerates a parameter with no definition object', () {
      final input = PendingInputDto.fromJson({
        'id': 'x',
        'inputs': [
          {'name': 'CONFIRM', 'type': 'BooleanParameterDefinition'},
        ],
      }).toDomain();

      expect(input.inputs.single.defaultValue, isNull);
      expect(input.inputs.single.choices, isNull);
    });

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
