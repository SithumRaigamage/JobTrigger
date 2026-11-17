import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_overview.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';

SonarQubeProject _p(String key, [String? name]) =>
    SonarQubeProject(key: key, name: name ?? key, lastAnalysisDate: null);

SonarQubeProjectSummary _s(
  QualityGateState gate, {
  int? bugs,
  int? vulns,
  int? smells,
}) => SonarQubeProjectSummary(
  gate: gate,
  bugs: bugs,
  vulnerabilities: vulns,
  codeSmells: smells,
);

void main() {
  test('counts each verdict and totals the analysed projects', () {
    final overview = buildSonarQubeOverview(
      [_p('a'), _p('b'), _p('c'), _p('d'), _p('e')],
      {
        'a': _s(QualityGateState.failed, bugs: 3, vulns: 1, smells: 10),
        'b': _s(QualityGateState.passed, bugs: 0, vulns: 0, smells: 5),
        'c': _s(QualityGateState.warning, bugs: 1, smells: 2),
        'd': _s(QualityGateState.none, bugs: 99, smells: 99), // not analysed
      },
    );

    expect(overview.failing, 1);
    expect(overview.passing, 1);
    expect(overview.warning, 1);
    expect(overview.notAnalysed, 1);
    expect(overview.unknown, 1); // 'e' has no summary yet
    expect(overview.total, 5);
    expect(overview.analysed, 3);
    // The never-analysed project's numbers are not in the totals.
    expect(overview.bugs, 4);
    expect(overview.vulnerabilities, 1);
    expect(overview.codeSmells, 17);
  });

  test('projects still loading are unknown, never passing', () {
    final overview = buildSonarQubeOverview([_p('a'), _p('b')], {});

    expect(overview.unknown, 2);
    expect(overview.passing, 0);
    expect(overview.needsAttention, isEmpty);
  });

  test('needs attention lists failed before warning, worst first', () {
    final overview = buildSonarQubeOverview(
      [_p('w', 'W'), _p('f1', 'F1'), _p('f2', 'F2'), _p('f3', 'A-third')],
      {
        'w': _s(QualityGateState.warning, bugs: 50),
        'f1': _s(QualityGateState.failed, bugs: 1, vulns: 1),
        'f2': _s(QualityGateState.failed, bugs: 5),
        'f3': _s(QualityGateState.failed, bugs: 1, vulns: 1),
      },
    );

    expect(overview.needsAttention.map((p) => p.key), [
      'f2', // most bugs + vulnerabilities
      'f3', // tie with f1: by name
      'f1',
      'w', // warning always after failed
    ]);
  });

  test('never-analysed projects are listed by name', () {
    final overview = buildSonarQubeOverview(
      [_p('z', 'Zed'), _p('a', 'alpha')],
      {'z': _s(QualityGateState.none), 'a': _s(QualityGateState.none)},
    );

    expect(overview.neverAnalysed.map((p) => p.name), ['alpha', 'Zed']);
    expect(overview.analysed, 0);
  });

  test('no projects is an empty overview', () {
    final overview = buildSonarQubeOverview([], {});

    expect(overview.total, 0);
    expect(overview.needsAttention, isEmpty);
  });
}
