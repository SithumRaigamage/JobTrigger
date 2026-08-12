import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/parameter_definition.dart';
import 'package:job_trigger/presentation/features/job_detail/parameter_form.dart';

void main() {
  testWidgets('reports initial defaults immediately, all stringified', (
    tester,
  ) async {
    Map<String, String>? reported;
    const params = [
      ParameterDefinition(
        name: 'BRANCH',
        type: 'StringParameterDefinition',
        defaultValue: 'main',
      ),
      ParameterDefinition(
        name: 'ENV',
        type: 'ChoiceParameterDefinition',
        choices: ['dev', 'staging', 'prod'],
      ),
      ParameterDefinition(
        name: 'DEBUG',
        type: 'BooleanParameterDefinition',
        defaultValue: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParameterForm(
            parameters: params,
            onChanged: (v) => reported = v,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(reported, isNotNull);
    expect(reported!['BRANCH'], 'main');
    // No explicit default -> falls back to the first choice.
    expect(reported!['ENV'], 'dev');
    // Boolean default stringified, not left as a bool.
    expect(reported!['DEBUG'], 'true');
  });

  testWidgets(
    'StringParameterDefinition renders a text field and reports edits',
    (tester) async {
      Map<String, String>? reported;
      const params = [
        ParameterDefinition(
          name: 'BRANCH',
          type: 'StringParameterDefinition',
          defaultValue: 'main',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParameterForm(
              parameters: params,
              onChanged: (v) => reported = v,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'release/2.0');
      await tester.pump();

      expect(reported!['BRANCH'], 'release/2.0');
    },
  );

  testWidgets(
    'ChoiceParameterDefinition renders a dropdown and reports the selection',
    (tester) async {
      Map<String, String>? reported;
      const params = [
        ParameterDefinition(
          name: 'ENV',
          type: 'ChoiceParameterDefinition',
          choices: ['dev', 'staging', 'prod'],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParameterForm(
              parameters: params,
              onChanged: (v) => reported = v,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('prod').last);
      await tester.pumpAndSettle();

      expect(reported!['ENV'], 'prod');
    },
  );

  testWidgets(
    'BooleanParameterDefinition renders a switch and reports true/false as strings',
    (tester) async {
      Map<String, String>? reported;
      const params = [
        ParameterDefinition(
          name: 'DEBUG',
          type: 'BooleanParameterDefinition',
          defaultValue: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ParameterForm(
              parameters: params,
              onChanged: (v) => reported = v,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(reported!['DEBUG'], 'false');

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(reported!['DEBUG'], 'true');
    },
  );

  testWidgets('multiple parameters all report together in one map', (
    tester,
  ) async {
    Map<String, String>? reported;
    const params = [
      ParameterDefinition(
        name: 'BRANCH',
        type: 'StringParameterDefinition',
        defaultValue: 'main',
      ),
      ParameterDefinition(
        name: 'DEBUG',
        type: 'BooleanParameterDefinition',
        defaultValue: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParameterForm(
            parameters: params,
            onChanged: (v) => reported = v,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(reported!.keys.toSet(), {'BRANCH', 'DEBUG'});
  });
}
