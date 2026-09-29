@Tags(['fixture'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/parameter_values.dart';

import 'fixture_support.dart';

/// P11-04 / US-JX-01: what actually reaches Jenkins for a password
/// parameter. `params-all` declares `DEPLOY_TOKEN` with a 22-character
/// stored default and logs only the received value's length.
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();
  const job = 'params-all';

  Future<String> runAndReadLog(Map<String, String> parameters) async {
    final build = await triggerAndAwaitStart(
      jenkins,
      job,
      parameters: parameters,
    );
    await awaitCompletion(jenkins, job, build.number);
    return expectOk(
      await jenkins.adminRepository().streamBuildLog(build.url),
    ).text;
  }

  Future<Map<String, String>> formDefaults() async {
    final detail = expectOk(
      await jenkins.adminRepository().fetchJobDetail(jenkins.jobUrl(job)),
    );
    final definitions = detail.parameterDefinitions;
    // What the app sends when the user leaves every field untouched --
    // except BASE_BUILD: an empty Run parameter is a Jenkins 500 (AUD-38,
    // fixed by P11-06), and the file parameter, which can't be sent as
    // form text. A unique BRANCH stops Jenkins merging this build into an
    // identical queued one (AUD-37).
    final values = effectiveParameterValues(definitions, {
      'BASE_BUILD': 'freestyle-simple#1',
      'BRANCH': 'p11-04-${DateTime.now().microsecondsSinceEpoch}',
    });
    return triggerParameters(definitions, values)..remove('config.json');
  }

  test('Jenkins never returns the stored password default', () async {
    final detail = expectOk(
      await jenkins.adminRepository().fetchJobDetail(jenkins.jobUrl(job)),
    );
    final token = detail.parameterDefinitions.singleWhere(
      (parameter) => parameter.name == 'DEPLOY_TOKEN',
    );
    expect(token.defaultValue, isNull);
    expect(initialParameterValue(token), '');
  });

  test('a blank password is omitted, so the server default is used', () async {
    final parameters = await formDefaults();
    expect(parameters.containsKey('DEPLOY_TOKEN'), isFalse);

    final log = await runAndReadLog(parameters);
    expect(log, contains('DEPLOY_TOKEN length: 22'));
  });

  test('the old behaviour -- sending it empty -- wiped the secret', () async {
    // Documents the bug US-JX-01 fixes: an explicit empty value overrides
    // the stored default.
    final parameters = {...await formDefaults(), 'DEPLOY_TOKEN': ''};

    final log = await runAndReadLog(parameters);
    expect(log, contains('DEPLOY_TOKEN length: 0'));
  });

  test('an entered password is sent and never appears in the log', () async {
    final parameters = {...await formDefaults(), 'DEPLOY_TOKEN': 'abc-secret'};

    final log = await runAndReadLog(parameters);
    expect(log, contains('DEPLOY_TOKEN length: 10'));
    expect(log, isNot(contains('abc-secret')));
  });
}
