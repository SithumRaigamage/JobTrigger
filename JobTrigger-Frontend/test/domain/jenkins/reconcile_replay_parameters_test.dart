import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/parameter_definition.dart';
import 'package:job_trigger/domain/jenkins/reconcile_replay_parameters.dart';

void main() {
  group('reconcileReplayParameters (US-PIPE-08)', () {
    test('pre-fills a known parameter with its historic value', () {
      const definitions = [
        ParameterDefinition(
          name: 'BRANCH',
          type: 'StringParameterDefinition',
          defaultValue: 'develop',
        ),
      ];

      final reconciled = reconcileReplayParameters(definitions, {
        'BRANCH': 'release/1.2',
      });

      expect(reconciled.single.defaultValue, 'release/1.2');
      // Other fields survive untouched.
      expect(reconciled.single.name, 'BRANCH');
      expect(reconciled.single.type, 'StringParameterDefinition');
    });

    test(
      'a parameter only in current definitions falls back to its current default',
      () {
        const definitions = [
          ParameterDefinition(
            name: 'NEW_PARAM',
            type: 'StringParameterDefinition',
            defaultValue: 'current-default',
          ),
        ];

        final reconciled = reconcileReplayParameters(definitions, const {});

        expect(reconciled.single.defaultValue, 'current-default');
      },
    );

    test(
      'a parameter only in historic values (removed from the job since) is dropped',
      () {
        const definitions = <ParameterDefinition>[];

        final reconciled = reconcileReplayParameters(definitions, {
          'REMOVED_PARAM': 'x',
        });

        expect(reconciled, isEmpty);
      },
    );

    test('mixed: known, new, and removed parameters all reconcile correctly', () {
      const definitions = [
        ParameterDefinition(name: 'BRANCH', type: 'StringParameterDefinition'),
        ParameterDefinition(
          name: 'NEW_PARAM',
          type: 'StringParameterDefinition',
          defaultValue: 'current-default',
        ),
      ];

      final reconciled = reconcileReplayParameters(definitions, {
        'BRANCH': 'release/1.2',
        'REMOVED_PARAM': 'x',
      });

      expect(reconciled, hasLength(2));
      expect(
        reconciled.firstWhere((d) => d.name == 'BRANCH').defaultValue,
        'release/1.2',
      );
      expect(
        reconciled.firstWhere((d) => d.name == 'NEW_PARAM').defaultValue,
        'current-default',
      );
    });

    test('no parameters at all returns an empty list', () {
      expect(reconcileReplayParameters(const [], const {}), isEmpty);
    });
  });
}
