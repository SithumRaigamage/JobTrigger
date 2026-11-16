import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_branch_ref.dart';

void main() {
  group('branch refs (US-SQ-QUALITY-10)', () {
    test('main has no query parameter and is not a choice', () {
      expect(const SonarQubeBranchRef.main().queryKey, isNull);
      expect(const SonarQubeBranchRef.main().label, 'Main branch');
      expect(const SonarQubeBranchRef.branch('dev').queryKey, 'branch');
      expect(
        const SonarQubeBranchRef.pullRequest('42').queryKey,
        'pullRequest',
      );
      expect(const SonarQubeBranchRef.pullRequest('42').label, 'PR 42');
    });

    test('branches and pull requests become choices, main is skipped', () {
      final choices = parseSonarQubeRefs(
        branches: {
          'branches': [
            {'name': 'main', 'isMain': true},
            {'name': 'feature/login', 'isMain': false},
          ],
        },
        pullRequests: {
          'pullRequests': [
            {'key': '42', 'title': 'Add login'},
          ],
        },
      );

      expect(choices.hasChoice, isTrue);
      expect(choices.refs.map((r) => r.label), ['feature/login', 'PR 42']);
      expect(choices.refs.first.kind, SonarQubeRefKind.branch);
      expect(choices.refs.last.kind, SonarQubeRefKind.pullRequest);
    });

    test('main only, or no endpoints at all, means no picker', () {
      expect(
        parseSonarQubeRefs(
          branches: {
            'branches': [
              {'name': 'main', 'isMain': true},
            ],
          },
        ).hasChoice,
        isFalse,
      );
      expect(parseSonarQubeRefs().hasChoice, isFalse);
      expect(
        parseSonarQubeRefs(branches: 'nope', pullRequests: 7).refs,
        isEmpty,
      );
    });

    test('malformed entries are skipped rather than shown blank', () {
      final choices = parseSonarQubeRefs(
        branches: {
          'branches': [
            {'name': '', 'isMain': false},
            {'isMain': false},
            {'name': 'dev'},
          ],
        },
        pullRequests: {
          'pullRequests': [
            {'key': ''},
            {'title': 'no key'},
          ],
        },
      );

      expect(choices.refs.map((r) => r.label), ['dev']);
    });
  });
}
