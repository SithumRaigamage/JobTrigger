import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/parameter_definition.dart';
import 'package:job_trigger/domain/jenkins/parameter_values.dart';
import 'package:job_trigger/presentation/features/job_detail/parameter_edits_notifier.dart';
import 'package:job_trigger/presentation/features/job_detail/parameter_form.dart';

/// Hosts a [ParameterForm] the way the app does: values from a
/// `ParameterEditsNotifier` through `effectiveParameterValues`.
class _Host extends ConsumerWidget {
  const _Host({required this.parameters, this.leadingSpace = 0});

  final List<ParameterDefinition> parameters;

  /// Pushes the form down a scrollable so a test can scroll it away.
  final double leadingSpace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = effectiveParameterValues(
      parameters,
      ref.watch(parameterEditsNotifierProvider('form')),
    );
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            SizedBox(height: leadingSpace),
            ParameterForm(
              parameters: parameters,
              values: values,
              onChanged: ref
                  .read(parameterEditsNotifierProvider('form').notifier)
                  .setValue,
            ),
            const SizedBox(height: 3000),
          ],
        ),
      ),
    );
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  List<ParameterDefinition> parameters, {
  double leadingSpace = 0,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _Host(parameters: parameters, leadingSpace: leadingSpace),
    ),
  );
  return container;
}

Map<String, String> _edits(ProviderContainer container) =>
    container.read(parameterEditsNotifierProvider('form'));

void main() {
  testWidgets('shows defaults and records edits by parameter name', (
    tester,
  ) async {
    final container = await _pump(tester, const [
      ParameterDefinition(
        name: 'BRANCH',
        type: 'StringParameterDefinition',
        defaultValue: 'main',
      ),
    ]);

    expect(find.text('main'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'release');
    expect(_edits(container), {'BRANCH': 'release'});
  });

  testWidgets('boolean parameters render a switch reporting "true"/"false"', (
    tester,
  ) async {
    final container = await _pump(tester, const [
      ParameterDefinition(
        name: 'DRY_RUN',
        type: 'BooleanParameterDefinition',
        defaultValue: true,
      ),
    ]);

    await tester.tap(find.byType(Switch));
    expect(_edits(container), {'DRY_RUN': 'false'});
  });

  testWidgets('choice parameters render a dropdown of the declared choices', (
    tester,
  ) async {
    final container = await _pump(tester, const [
      ParameterDefinition(
        name: 'TARGET',
        type: 'ChoiceParameterDefinition',
        choices: ['staging', 'production'],
      ),
    ]);

    await tester.tap(find.text('staging'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('production').last);
    await tester.pumpAndSettle();
    expect(_edits(container), {'TARGET': 'production'});
  });

  testWidgets('a value outside the declared choices does not crash', (
    tester,
  ) async {
    await _pump(tester, const [
      ParameterDefinition(
        name: 'TARGET',
        type: 'ChoiceParameterDefinition',
        choices: ['staging'],
        // e.g. a replayed value the job has since removed.
        defaultValue: 'retired-env',
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  group('password parameters (US-JX-01)', () {
    const token = ParameterDefinition(
      name: 'DEPLOY_TOKEN',
      type: passwordParameterType,
      description: 'Secret token',
    );

    testWidgets('are masked, start empty, and disable suggestions', (
      tester,
    ) async {
      await _pump(tester, const [token]);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(field.enableSuggestions, isFalse);
      expect(field.autocorrect, isFalse);
      expect(field.controller!.text, isEmpty);
      expect(
        find.textContaining('Leave blank to use the server default'),
        findsOneWidget,
      );
    });

    testWidgets('the eye toggle reveals and re-hides the value', (
      tester,
    ) async {
      await _pump(tester, const [token]);

      await tester.tap(find.byTooltip('Show DEPLOY_TOKEN'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
      );

      await tester.tap(find.byTooltip('Hide DEPLOY_TOKEN'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );
    });
  });

  testWidgets(
    'an edit survives the form scrolling off-screen and back (AUD-18)',
    (tester) async {
      await _pump(tester, const [
        ParameterDefinition(
          name: 'BRANCH',
          type: 'StringParameterDefinition',
          defaultValue: 'main',
        ),
      ]);

      await tester.enterText(find.byType(TextFormField), 'hotfix');
      // A focused field is kept alive by the list; the value used to be
      // lost once the keyboard was dismissed and the user scrolled.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      // Far enough that the ListView disposes the form entirely.
      await tester.drag(find.byType(ListView), const Offset(0, -2500));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, 2500));
      await tester.pumpAndSettle();
      expect(find.text('hotfix'), findsOneWidget);
      expect(find.text('main'), findsNothing);
    },
  );
}
