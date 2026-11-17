import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/tools/tool_catalog.dart';
import 'package:job_trigger/presentation/features/subscription/paywall_reason.dart';

/// The paywall must not promise tools the release doesn't have
/// (release/tools.json): "together" needs at least two.
ToolCatalog release(String version) => ToolCatalog(
  release: version,
  versions: ToolCatalog.parse(
    File('config/tools.json').readAsStringSync(),
  ).versions,
);

/// The shipped manifest releases all three tools at 1.0. A staged fixture
/// keeps the single- and two-tool copy paths (and their version comparison)
/// covered without changing the release schedule in tools.json.
ToolCatalog staged(String version) => ToolCatalog(
  release: version,
  versions: const {
    'jenkins': '1.0',
    'sonarqube': '1.1',
    'githubActions': '1.2',
    'gitlab': '1.3',
    'circleci': '1.3',
  },
);

const reasons = [
  'maxCredentialsTotal',
  'maxCredentialsPerTool',
  'multiTool',
  'primaryCooldown',
  'locked',
  'backgroundWatch',
  'homeWidget',
  'maxPinnedJobs',
  'insights',
  'unknown',
  null,
];

void main() {
  tearDown(() => ToolCatalog.current = ToolCatalog.allTools);

  test('every tool released: the copy is what it always was', () {
    expect(
      paywallHeadline('multiTool'),
      'Use Jenkins, GitHub Actions and SonarQube together',
    );
    expect(proBenefits, [
      'Unlimited servers and accounts',
      'Jenkins, GitHub Actions and SonarQube together',
      'Build-finished notifications',
      'Home-screen widget',
      'Unlimited pinned jobs',
      'Build trends and insights',
    ]);
  });

  test('release 1.0 names all three tools it ships', () {
    ToolCatalog.current = release('1.0');
    expect(
      paywallHeadline('multiTool'),
      'Use Jenkins, GitHub Actions and SonarQube together',
    );
    expect(proBenefits[1], 'Jenkins, GitHub Actions and SonarQube together');
  });

  test('a one-tool release names no other tool and promises none together', () {
    ToolCatalog.current = staged('1.0');
    final everything = [
      ...proBenefits,
      for (final reason in reasons) paywallHeadline(reason),
    ].join('\n');

    expect(everything, isNot(contains('GitHub')));
    expect(everything, isNot(contains('SonarQube')));
    expect(paywallHeadline('multiTool'), 'Use more tools as they release');
    expect(proBenefits[1], 'More tools together as they release');
  });

  test('release 1.1 names exactly the tools it ships', () {
    ToolCatalog.current = staged('1.1');
    expect(paywallHeadline('multiTool'), 'Use Jenkins and SonarQube together');
    expect(proBenefits[1], 'Jenkins and SonarQube together');
  });

  test('release 1.2 names all three', () {
    ToolCatalog.current = staged('1.2');
    expect(proBenefits[1], 'Jenkins, GitHub Actions and SonarQube together');
  });
}
