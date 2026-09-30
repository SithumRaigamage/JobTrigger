@Tags(['fixture'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/domain/jenkins/pending_input.dart';

import 'fixture_support.dart';

/// P11-02: US-PIPE-05 (input-step approval) end-to-end against a real paused
/// pipeline -- the verification P7-07 shipped without.
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();

  Future<(String buildUrl, int number, PendingInput input)> startPaused(
    String jobPath,
  ) async {
    final build = await triggerAndAwaitStart(jenkins, jobPath);
    final input = await pollUntil(
      () async => expectOk(
        await jenkins.adminRepository().fetchPendingInput(build.url),
      ),
      description: '$jobPath #${build.number} to pause on input',
    );
    return (build.url, build.number, input);
  }

  Future<String> consoleOf(String buildUrl) async {
    final chunk = expectOk(
      await jenkins.adminRepository().streamBuildLog(buildUrl),
    );
    return chunk.text;
  }

  test('detects a parameterless paused input and its labels', () async {
    final (buildUrl, number, input) = await startPaused(
      'pipeline-input-simple',
    );

    expect(input.id, 'PromoteGate');
    expect(input.message, 'Promote to staging?');
    expect(input.proceedText, 'Promote');
    expect(input.inputs, isEmpty);

    // Leave the fixture clean for the next test.
    expectOk(
      await jenkins.adminRepository().submitInput(
        buildUrl: buildUrl,
        inputId: input.id,
        proceed: false,
      ),
    );
    await awaitCompletion(jenkins, 'pipeline-input-simple', number);
  });

  test(
    'proceed on a parameterless input resumes the build to SUCCESS',
    () async {
      final (buildUrl, number, input) = await startPaused(
        'pipeline-input-simple',
      );

      expectOk(
        await jenkins.adminRepository().submitInput(
          buildUrl: buildUrl,
          inputId: input.id,
          proceed: true,
        ),
      );

      final done = await awaitCompletion(
        jenkins,
        'pipeline-input-simple',
        number,
      );
      expect(done.result, 'SUCCESS');
    },
  );

  test('abort ends the build as ABORTED', () async {
    final (buildUrl, number, input) = await startPaused(
      'pipeline-input-simple',
    );

    expectOk(
      await jenkins.adminRepository().submitInput(
        buildUrl: buildUrl,
        inputId: input.id,
        proceed: false,
      ),
    );

    final done = await awaitCompletion(
      jenkins,
      'pipeline-input-simple',
      number,
    );
    expect(done.result, 'ABORTED');
  });

  test('detects input parameters, including the password parameter', () async {
    final (buildUrl, number, input) = await startPaused(
      'pipeline-input-params',
    );

    expect(input.id, 'DeployGate');
    expect(input.inputs.map((parameter) => parameter.name), [
      'VERSION',
      'REGION',
      'OTP',
    ]);
    // Defaults and choices come from `definition` (P11-02's DTO fix).
    expect(input.inputs[0].defaultValue, '1.2.3');
    expect(input.inputs[1].choices, ['eu-west-1', 'us-east-1']);
    expect(input.inputs[1].defaultValue, 'eu-west-1');
    expect(input.inputs.map((parameter) => parameter.type), [
      'StringParameterDefinition',
      'ChoiceParameterDefinition',
      'PasswordParameterDefinition',
    ]);

    expectOk(
      await jenkins.adminRepository().submitInput(
        buildUrl: buildUrl,
        inputId: input.id,
        proceed: false,
      ),
    );
    await awaitCompletion(jenkins, 'pipeline-input-params', number);
  });

  test('submit with parameters delivers the values to the pipeline', () async {
    final (buildUrl, number, input) = await startPaused(
      'pipeline-input-params',
    );

    expectOk(
      await jenkins.adminRepository().submitInput(
        buildUrl: buildUrl,
        inputId: input.id,
        proceed: true,
        parameters: {
          'VERSION': '9.9.9',
          'REGION': 'us-east-1',
          'OTP': 'one-time-secret',
        },
      ),
    );

    final done = await awaitCompletion(
      jenkins,
      'pipeline-input-params',
      number,
    );
    expect(done.result, 'SUCCESS');
    final log = await consoleOf(buildUrl);
    expect(log, contains('Deploying 9.9.9 to us-east-1'));
    expect(log, isNot(contains('one-time-secret')));
  });

  test(
    'a read-only user cannot submit parameters either (PermissionFailure)',
    () async {
      final (buildUrl, number, input) = await startPaused(
        'pipeline-input-params',
      );

      final result = await jenkins.viewerRepository().submitInput(
        buildUrl: buildUrl,
        inputId: input.id,
        proceed: true,
        parameters: {'VERSION': '6.6.6', 'REGION': 'eu-west-1', 'OTP': 'x'},
      );
      expect((result as Err).error, isA<PermissionFailure>());

      expectOk(
        await jenkins.adminRepository().submitInput(
          buildUrl: buildUrl,
          inputId: input.id,
          proceed: false,
        ),
      );
      await awaitCompletion(jenkins, 'pipeline-input-params', number);
    },
  );

  test(
    'a read-only user cannot approve (PermissionFailure), build stays paused',
    () async {
      final (buildUrl, number, input) = await startPaused(
        'pipeline-input-simple',
      );

      final result = await jenkins.viewerRepository().submitInput(
        buildUrl: buildUrl,
        inputId: input.id,
        proceed: true,
      );
      expect(result, isA<Err<void, AppFailure>>());
      expect((result as Err).error, isA<PermissionFailure>());

      final stillPaused = expectOk(
        await jenkins.adminRepository().fetchPendingInput(buildUrl),
      );
      expect(stillPaused, isNotNull);

      expectOk(
        await jenkins.adminRepository().submitInput(
          buildUrl: buildUrl,
          inputId: input.id,
          proceed: false,
        ),
      );
      await awaitCompletion(jenkins, 'pipeline-input-simple', number);
    },
  );
}
