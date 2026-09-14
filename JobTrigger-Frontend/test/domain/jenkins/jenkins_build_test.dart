import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/build_artifact.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/scm_change.dart';
import 'package:job_trigger/domain/jenkins/upstream_cause.dart';

void main() {
  group('JenkinsBuild.copyWith', () {
    const original = JenkinsBuild(
      number: 5,
      url: 'https://jenkins.test/job/x/5/',
      result: 'SUCCESS',
      timestamp: 1700000000000,
      duration: 1000,
      estimatedDuration: 1200,
      building: false,
      displayName: '#5',
      causes: ['Started by user Jane Doe'],
      changes: [ScmChange(author: 'Jane Doe', message: 'Fix bug')],
      artifacts: [
        BuildArtifact(fileName: 'app.apk', relativePath: 'build/app.apk'),
      ],
      upstreamCause: UpstreamCause(
        projectName: 'foo',
        url: 'https://jenkins.test/job/foo/',
      ),
      parameterValues: {'BRANCH': 'main'},
    );

    test('preserves every field not explicitly overridden', () {
      final copy = original.copyWith(url: 'https://internal.test/job/x/5/');

      expect(copy.url, 'https://internal.test/job/x/5/');
      expect(copy.number, original.number);
      expect(copy.result, original.result);
      expect(copy.timestamp, original.timestamp);
      expect(copy.duration, original.duration);
      expect(copy.estimatedDuration, original.estimatedDuration);
      expect(copy.building, original.building);
      expect(copy.displayName, original.displayName);
      // The exact regression P7-01/P7-02 hit: a field-by-field
      // reconstruction that forgot `causes` (and would have forgotten
      // `changes` too) instead of copying the source build.
      expect(copy.causes, original.causes);
      expect(copy.changes, original.changes);
      expect(copy.artifacts, original.artifacts);
      expect(copy.upstreamCause, original.upstreamCause);
      expect(copy.parameterValues, original.parameterValues);
    });

    test('overrides only the given fields', () {
      final copy = original.copyWith(result: 'ABORTED', building: false);

      expect(copy.result, 'ABORTED');
      expect(copy.building, isFalse);
      expect(copy.number, original.number);
      expect(copy.causes, original.causes);
      expect(copy.changes, original.changes);
      expect(copy.artifacts, original.artifacts);
      expect(copy.upstreamCause, original.upstreamCause);
      expect(copy.parameterValues, original.parameterValues);
    });
  });
}
