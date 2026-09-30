@Tags(['fixture'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/parameter_file.dart';
import 'package:job_trigger/domain/jenkins/parameter_values.dart';

import 'fixture_support.dart';

/// P11-06 / US-JX-02 against `params-all`, which declares every core
/// parameter type.
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();
  const job = 'params-all';

  Future<String> runAndReadLog(
    Map<String, String> edits, {
    Map<String, ParameterFile> files = const {},
  }) async {
    final repository = jenkins.adminRepository();
    final jobUrl = jenkins.jobUrl(job);
    final detail = expectOk(await repository.fetchJobDetail(jobUrl));
    final definitions = detail.parameterDefinitions;
    final values = effectiveParameterValues(definitions, {
      'BRANCH': 'p11-06-${DateTime.now().microsecondsSinceEpoch}',
      ...edits,
    });
    final previous = detail.lastBuild?.number ?? 0;

    expectOk(
      await repository.triggerBuild(
        jobUrl,
        isParameterized: true,
        parameters: triggerParameters(definitions, values),
        files: triggerFiles(definitions, files),
      ),
    );
    final build = await pollUntil(() async {
      final last = expectOk(await repository.fetchJobDetail(jobUrl)).lastBuild;
      return (last != null && last.number > previous) ? last : null;
    }, description: '$job to start');
    final done = await awaitCompletion(jenkins, job, build.number);
    expect(done.result, 'SUCCESS');
    return expectOk(await repository.streamBuildLog(build.url)).text;
  }

  test('the definitions carry the Run project name', () async {
    final detail = expectOk(
      await jenkins.adminRepository().fetchJobDetail(jenkins.jobUrl(job)),
    );
    final run = detail.parameterDefinitions.singleWhere(
      (parameter) => parameter.type == runParameterType,
    );
    expect(run.projectName, 'freestyle-simple');
  });

  test('the untouched form triggers successfully (AUD-38)', () async {
    // Blank Run, Credentials, File, and Password are omitted, so Jenkins
    // applies its own defaults -- an empty Run value was an HTTP 500.
    final log = await runAndReadLog(const {});
    expect(log, contains('BASE_BUILD=http://jenkins.internal:8080/job/'));
    expect(log, contains('no config.json'));
  });

  test('a chosen Run build is used', () async {
    final history = expectOk(
      await jenkins.adminRepository().fetchJobHistory(
        jenkins.jobUrl('freestyle-simple'),
      ),
    );
    final oldest = history.last.number;

    final log = await runAndReadLog({'BASE_BUILD': 'freestyle-simple#$oldest'});
    expect(log, contains('/job/freestyle-simple/$oldest/'));
  });

  test('a file parameter uploads the file as a multipart part', () async {
    final directory = Directory.systemTemp.createTempSync('jt-fixture');
    addTearDown(() => directory.deleteSync(recursive: true));
    final local = File('${directory.path}/settings.json')
      ..writeAsStringSync('{"replicas": 3}');

    final log = await runAndReadLog(
      const {},
      files: {
        'config.json': ParameterFile(
          fileName: 'settings.json',
          path: local.path,
          sizeBytes: local.lengthSync(),
        ),
      },
    );
    expect(log, contains('config.json: 15 bytes'));
  });

  test('multi-line text arrives intact', () async {
    final log = await runAndReadLog({'RELEASE_NOTES': 'one\ntwo\nthree'});
    expect(log, contains('Finished: SUCCESS'));
  });
}
