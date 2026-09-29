import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/parameter_definition.dart';
import 'package:job_trigger/domain/jenkins/parameter_values.dart';

const _branch = ParameterDefinition(
  name: 'BRANCH',
  type: 'StringParameterDefinition',
  defaultValue: 'main',
);
const _target = ParameterDefinition(
  name: 'TARGET',
  type: 'ChoiceParameterDefinition',
  choices: ['staging', 'production'],
);
const _dryRun = ParameterDefinition(
  name: 'DRY_RUN',
  type: 'BooleanParameterDefinition',
  defaultValue: true,
);
const _token = ParameterDefinition(
  name: 'DEPLOY_TOKEN',
  type: passwordParameterType,
  // Even if a server ever sent one, a secret's default is never used.
  defaultValue: 'leaked-default',
);
const _notes = ParameterDefinition(
  name: 'NOTES',
  type: 'TextParameterDefinition',
  defaultValue: 'line one\nline two',
);

void main() {
  group('initialParameterValue', () {
    test('uses the declared default, stringified', () {
      expect(initialParameterValue(_branch), 'main');
      expect(initialParameterValue(_dryRun), 'true');
    });

    test('falls back to the first choice, then empty', () {
      expect(initialParameterValue(_target), 'staging');
      expect(
        initialParameterValue(
          const ParameterDefinition(
            name: 'X',
            type: 'StringParameterDefinition',
          ),
        ),
        '',
      );
    });

    test('never pre-fills a secret (US-JX-01)', () {
      expect(initialParameterValue(_token), '');
    });
  });

  group('effectiveParameterValues', () {
    test('overlays edits on defaults and drops edits for removed params', () {
      final values = effectiveParameterValues(
        [_branch, _target],
        {'TARGET': 'production', 'REMOVED': 'x'},
      );
      expect(values, {'BRANCH': 'main', 'TARGET': 'production'});
    });
  });

  group('triggerParameters', () {
    test('omits a blank secret so Jenkins keeps its stored default', () {
      final body = triggerParameters(
        [_branch, _token],
        {'BRANCH': 'main', 'DEPLOY_TOKEN': ''},
      );
      expect(body, {'BRANCH': 'main'});
      expect(body.containsKey('DEPLOY_TOKEN'), isFalse);
    });

    test('sends a secret the user actually entered', () {
      final body = triggerParameters([_token], {'DEPLOY_TOKEN': 's3cret'});
      expect(body, {'DEPLOY_TOKEN': 's3cret'});
    });

    test('still sends blank non-secret values explicitly', () {
      final body = triggerParameters([_branch], {'BRANCH': ''});
      expect(body, {'BRANCH': ''});
    });
  });

  group('parameterSummary', () {
    test('masks secrets and never includes their value', () {
      final entered = parameterSummary([_token], {'DEPLOY_TOKEN': 's3cret'});
      final blank = parameterSummary([_token], {'DEPLOY_TOKEN': ''});

      expect(entered.single.display, '••••');
      expect(entered.single.display, isNot(contains('s3cret')));
      expect(blank.single.display, 'server default');
    });

    test('collapses multi-line values and marks empty ones', () {
      final rows = parameterSummary(
        [_notes, _branch],
        {'NOTES': 'line one\nline two', 'BRANCH': ''},
      );
      expect(rows[0].display, 'line one …');
      expect(rows[1].display, '(empty)');
    });
  });
}
