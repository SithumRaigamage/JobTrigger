import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/safety/server_safety.dart';

void main() {
  group('ServerSafety', () {
    test('starts with no flags', () {
      const safety = ServerSafety();
      expect(safety.readOnly, isEmpty);
      expect(safety.protectedJobs, isEmpty);
      expect(safety.isReadOnly(SafetyTool.jenkins, 's1'), isFalse);
      expect(safety.isProtected(SafetyTool.jenkins, 'job'), isFalse);
    });

    test('read-only flags are keyed by tool and credential', () {
      const safety = ServerSafety();
      final jenkins = safety.withReadOnly(SafetyTool.jenkins, 's1', true);
      final both = jenkins.withReadOnly(SafetyTool.githubActions, 'g1', true);

      expect(both.isReadOnly(SafetyTool.jenkins, 's1'), isTrue);
      expect(both.isReadOnly(SafetyTool.jenkins, 's2'), isFalse);
      expect(both.isReadOnly(SafetyTool.githubActions, 'g1'), isTrue);
      expect(both.isReadOnly(SafetyTool.sonarqube, 'g1'), isFalse);

      // Turning a flag off is scoped to just that key.
      final off = both.withReadOnly(SafetyTool.jenkins, 's1', false);
      expect(off.isReadOnly(SafetyTool.jenkins, 's1'), isFalse);
      expect(off.isReadOnly(SafetyTool.githubActions, 'g1'), isTrue);
    });

    test('protected-job keys ignore surrounding whitespace and slashes', () {
      const safety = ServerSafety();
      final marked = safety.withProtected(SafetyTool.jenkins, '  job/api/ ', true);

      expect(
        marked.isProtected(SafetyTool.jenkins, 'job/api'),
        isTrue,
        reason: 'the same job normalises to the same key',
      );
      expect(marked.isProtected(SafetyTool.jenkins, 'job/api/'), isTrue);
      // Case is significant: Jenkins job names are case-sensitive.
      expect(marked.isProtected(SafetyTool.jenkins, 'JOB/api'), isFalse);
      // Protection is per tool.
      expect(marked.isProtected(SafetyTool.githubActions, 'job/api'), isFalse);
    });

    test('round-trips through JSON, sorted for stable storage', () {
      final safety = const ServerSafety()
          .withReadOnly(SafetyTool.sonarqube, 'q1', true)
          .withReadOnly(SafetyTool.jenkins, 's1', true)
          .withProtected(SafetyTool.jenkins, 'deploy', true);

      final json = safety.toJson();
      expect(json['readOnly'], ['jenkins:s1', 'sonarqube:q1']);

      final restored = ServerSafety.fromJson(json);
      expect(restored, safety);
    });

    test('tolerates malformed JSON fields', () {
      final safety = ServerSafety.fromJson({
        'readOnly': 'not a list',
        'protectedJobs': [1, 2],
      });
      // String fields are skipped by the cast guard rather than crashing.
      expect(safety.readOnly, isEmpty);
    });
  });
}
