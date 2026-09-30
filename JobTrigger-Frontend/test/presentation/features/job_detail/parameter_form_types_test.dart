import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/parameter_definition.dart';
import 'package:job_trigger/domain/jenkins/parameter_file.dart';
import 'package:job_trigger/domain/jenkins/parameter_values.dart';
import 'package:job_trigger/presentation/features/job_detail/parameter_form.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';

import '../../../support/fake_jenkins_repository.dart';

class _HistoryRepository extends FakeJenkinsRepository {
  final requested = <String>[];

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl,
  ) async {
    requested.add(jobUrl);
    return const Ok([
      JenkinsBuild(number: 9, url: 'u9', timestamp: 0, result: 'SUCCESS'),
      JenkinsBuild(number: 8, url: 'u8', timestamp: 0, result: 'FAILURE'),
    ]);
  }
}

class _StubServer extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 's',
    serverName: 's',
    jenkinsURL: 'https://ci.test',
    username: 'u',
    secret: 'x',
  );
}

Future<
  ({
    List<(String, String)> changes,
    List<String> picks,
    List<String> removes,
    _HistoryRepository repo,
  })
>
_pump(
  WidgetTester tester,
  List<ParameterDefinition> parameters, {
  Map<String, String> values = const {},
  Map<String, ParameterFile> files = const {},
  bool uploads = true,
}) async {
  final changes = <(String, String)>[];
  final picks = <String>[];
  final removes = <String>[];
  final repo = _HistoryRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        jenkinsRepositoryProvider.overrideWithValue(repo),
        activeServerNotifierProvider.overrideWith(_StubServer.new),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ParameterForm(
              parameters: parameters,
              values: effectiveParameterValues(parameters, values),
              onChanged: (name, value) => changes.add((name, value)),
              files: files,
              onPickFile: uploads ? picks.add : null,
              onRemoveFile: uploads ? removes.add : null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (changes: changes, picks: picks, removes: removes, repo: repo);
}

void main() {
  testWidgets('text parameters are multi-line', (tester) async {
    await _pump(tester, const [
      ParameterDefinition(name: 'NOTES', type: textParameterType),
    ]);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLines, 8);
    expect(field.keyboardType, TextInputType.multiline);
  });

  testWidgets(
    'run parameters pick from the project builds, defaulting to the server',
    (tester) async {
      final result = await _pump(tester, const [
        ParameterDefinition(
          name: 'BASE_BUILD',
          type: runParameterType,
          projectName: 'team/api',
        ),
      ]);

      expect(result.repo.requested, ['https://ci.test/job/team/job/api/']);
      expect(find.text('Server default (latest build)'), findsOneWidget);

      await tester.tap(find.text('Server default (latest build)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('#8 · FAILURE').last);
      await tester.pumpAndSettle();

      expect(result.changes, [('BASE_BUILD', 'team/api#8')]);
    },
  );

  testWidgets('credentials parameters explain they take an ID', (tester) async {
    await _pump(tester, const [
      ParameterDefinition(name: 'CREDS', type: credentialsParameterType),
    ]);

    expect(find.textContaining('Credentials ID, not a secret'), findsOneWidget);
  });

  testWidgets('file parameters show the chosen file and offer replace/remove', (
    tester,
  ) async {
    final result = await _pump(
      tester,
      const [ParameterDefinition(name: 'config.json', type: fileParameterType)],
      files: const {
        'config.json': ParameterFile(
          fileName: 'cfg.json',
          path: '/cfg.json',
          sizeBytes: 2048,
        ),
      },
    );

    expect(find.text('cfg.json · 2.0 KB'), findsOneWidget);
    await tester.tap(find.text('Replace'));
    await tester.tap(find.byTooltip('Remove cfg.json'));
    expect(result.picks, ['config.json']);
    expect(result.removes, ['config.json']);
  });

  testWidgets('file parameters say when uploads are unavailable', (
    tester,
  ) async {
    await _pump(tester, const [
      ParameterDefinition(name: 'config.json', type: fileParameterType),
    ], uploads: false);

    expect(find.text("File upload isn't available here"), findsOneWidget);
    expect(find.text('Choose'), findsNothing);
  });

  testWidgets('unknown plugin types are labelled as sent-as-text', (
    tester,
  ) async {
    await _pump(tester, const [
      ParameterDefinition(name: 'TAG', type: 'GitParameterDefinition'),
      ParameterDefinition(
        name: 'COLOR',
        type: 'ChoiceParameterDefinitionFromPlugin',
        choices: ['red', 'blue'],
      ),
    ]);

    expect(
      find.textContaining('Unsupported type (GitParameterDefinition)'),
      findsOneWidget,
    );
    // A plugin type with choices still gets a dropdown.
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('red'), findsOneWidget);
  });
}
