import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';

void main() {
  test('toggling a type or severity adds then removes it', () {
    var f = const SonarQubeIssueFilter();
    expect(f.isEmpty, isTrue);

    f = f.toggleType('BUG').toggleSeverity('MAJOR');
    expect(f.types, {'BUG'});
    expect(f.severities, {'MAJOR'});
    expect(f.isEmpty, isFalse);

    f = f.toggleType('BUG');
    expect(f.types, isEmpty);
    expect(f.severities, {'MAJOR'});
  });

  test('filters with the same choices are equal, whatever the order', () {
    final a = const SonarQubeIssueFilter()
        .toggleType('BUG')
        .toggleType('CODE_SMELL');
    final b = const SonarQubeIssueFilter()
        .toggleType('CODE_SMELL')
        .toggleType('BUG');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(const SonarQubeIssueFilter()));
  });

  test('labels are readable, including values SonarQube adds later', () {
    expect(sonarQubeIssueTypeLabel('CODE_SMELL'), 'Code smell');
    expect(sonarQubeIssueTypeLabel('SECURITY_HOTSPOT'), 'Security hotspot');
    expect(sonarQubeSeverityLabel('BLOCKER'), 'Blocker');
  });

  test('location joins file and line, and tolerates either missing', () {
    const base = SonarQubeIssue(
      key: 'k',
      type: 'BUG',
      severity: 'MAJOR',
      message: 'm',
      file: 'a/B.java',
      line: 3,
    );
    expect(base.location, 'a/B.java:3');
    const noLine = SonarQubeIssue(
      key: 'k',
      type: 'BUG',
      severity: 'MAJOR',
      message: 'm',
      file: 'a/B.java',
      line: null,
    );
    expect(noLine.location, 'a/B.java');
    const none = SonarQubeIssue(
      key: 'k',
      type: 'BUG',
      severity: 'MAJOR',
      message: 'm',
      file: null,
      line: null,
    );
    expect(none.location, isNull);
  });
}
