import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/github/workflow_inputs.dart';

void main() {
  test('keeps named rows, trimming names but not values', () {
    final r = cleanWorkflowInputs([(' env ', ' prod '), ('debug', 'true')]);
    expect(r.isValid, isTrue);
    expect(r.inputs, {'env': ' prod ', 'debug': 'true'});
  });

  test('ignores fully blank rows', () {
    final r = cleanWorkflowInputs([('', ''), ('a', '1'), ('  ', '')]);
    expect(r.inputs, {'a': '1'});
  });

  test('a value with no name is an error, not silently dropped', () {
    final r = cleanWorkflowInputs([('', 'x')]);
    expect(r.isValid, isFalse);
    expect(r.error, contains('name'));
  });

  test('a repeated name is an error, not silently overwritten', () {
    final r = cleanWorkflowInputs([('a', '1'), ('a', '2')]);
    expect(r.isValid, isFalse);
    expect(r.error, contains('"a"'));
  });

  test('no rows is valid and empty', () {
    expect(cleanWorkflowInputs([]).inputs, isEmpty);
  });
}
