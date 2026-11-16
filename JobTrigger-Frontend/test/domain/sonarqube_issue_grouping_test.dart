import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue_grouping.dart';

void main() {
  group('issue grouping (US-SQ-ISSUES-02)', () {
    test('reads the requested facet, biggest group first', () {
      final groups = sonarQubeIssueGroups([
        {
          'property': 'files',
          'values': [
            {'val': 'src/a.dart', 'count': 2},
            {'val': 'src/b.dart', 'count': 7},
          ],
        },
        {
          'property': 'rules',
          'values': [
            {'val': 'dart:S123', 'count': 9},
          ],
        },
      ], SonarQubeIssueGrouping.file);

      expect(groups.map((g) => g.label), ['src/b.dart', 'src/a.dart']);
      expect(groups.first.count, 7);
    });

    test('no grouping asks for no facet and reads nothing', () {
      final groups = sonarQubeIssueGroups([
        {
          'property': 'files',
          'values': [
            {'val': 'src/a.dart', 'count': 2},
          ],
        },
      ], SonarQubeIssueGrouping.none);

      expect(groups, isEmpty);
      expect(SonarQubeIssueGrouping.none.facet, isEmpty);
      expect(SonarQubeIssueGrouping.severity.facet, 'severities');
      expect(SonarQubeIssueGrouping.none.isGrouped, isFalse);
    });

    test('malformed facets are skipped, a missing one is no groups', () {
      expect(
        sonarQubeIssueGroups('nope', SonarQubeIssueGrouping.rule),
        isEmpty,
      );
      expect(
        sonarQubeIssueGroups([
          {
            'property': 'rules',
            'values': [
              {'val': '', 'count': 3},
              {'val': 'dart:S1'},
              {'count': 4},
              {'val': 'dart:S2', 'count': 1},
            ],
          },
        ], SonarQubeIssueGrouping.rule).map((g) => g.label),
        ['dart:S2'],
      );
    });
  });
}
