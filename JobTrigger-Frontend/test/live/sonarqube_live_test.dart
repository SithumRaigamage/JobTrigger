@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/datasources/sonarqube_client_factory.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue_actions.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_metrics.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_worst_files.dart';

/// P10-14 / P10-15: every SonarQube call the app makes, against a real
/// server, through the app's own client and repository. Skipped unless
/// `SONARQUBE_LIVE_URL`, `SONARQUBE_LIVE_TOKEN` and `SONARQUBE_LIVE_PROJECT`
/// are set, so a normal `flutter test` never needs a server:
///
///   SONARQUBE_LIVE_URL=http://localhost:9000 \
///   SONARQUBE_LIVE_TOKEN=YOUR_USER_TOKEN SONARQUBE_LIVE_PROJECT=PROJECT_KEY \
///   flutter test test/live/sonarqube_live_test.dart
///
/// The write tests change data on that server (assign, transition, comment,
/// review): point it at a lab project, never a real one.
void main() {
  final env = Platform.environment;
  final url = env['SONARQUBE_LIVE_URL'];
  final token = env['SONARQUBE_LIVE_TOKEN'];
  final project = env['SONARQUBE_LIVE_PROJECT'];
  final skip = (url == null || token == null || project == null)
      ? 'set SONARQUBE_LIVE_URL, _TOKEN and _PROJECT to run'
      : false;

  late SonarQubeRepositoryImpl repo;
  setUp(() {
    if (skip != false) return;
    repo = SonarQubeRepositoryImpl(
      buildSonarQubeDio(baseUrl: url!, token: token),
    );
  });

  T ok<T>(Result<T, AppFailure> result) {
    expect(result, isA<Ok<T, AppFailure>>(), reason: '$result');
    return (result as Ok<T, AppFailure>).value;
  }

  group('reads', () {
    test('projects, summaries, project by key', () async {
      final page = ok(await repo.fetchProjects());
      expect(page.projects.map((p) => p.key), contains(project));
      final summaries = ok(await repo.fetchProjectSummaries([project!]));
      expect(summaries[project], isNotNull);
      expect(ok(await repo.fetchProjectByKey(project)).key, project);
      final missing = await repo.fetchProjectByKey('no-such-project-key');
      expect(missing, isA<Err<dynamic, AppFailure>>());
    }, skip: skip);

    test('gate, measures, new code, deltas, history, analyses', () async {
      ok(await repo.fetchQualityGate(project!));
      expect(ok(await repo.fetchMeasures(project)), isNotEmpty);
      ok(await repo.fetchNewCodeMeasures(project));
      ok(await repo.fetchMeasureDeltas(project));
      ok(await repo.fetchMeasureHistory(project, sonarQubeMeasureKeys.first));
      ok(await repo.fetchAnalysisHistory(project));
      ok(await repo.fetchAnalysisStatus(project));
      ok(await repo.fetchServerInfo());
      ok(await repo.fetchProjectRefs(project));
    }, skip: skip);

    test('issues, my issues, the four searches, file issues', () async {
      final page = ok(await repo.fetchIssues(project!));
      expect(page.total, greaterThan(0));
      ok(await repo.fetchMyIssues());
      final issue = page.issues.first;
      ok(await repo.searchIssues(issue.rule!));
      ok(
        await repo.searchIssues(
          issue.key,
          field: SonarQubeIssueSearchField.issueKey,
        ),
      );
      ok(
        await repo.searchIssues(
          issue.file ?? 'x',
          field: SonarQubeIssueSearchField.file,
        ),
      );
      ok(
        await repo.searchIssues(
          'bad-practice',
          field: SonarQubeIssueSearchField.tag,
        ),
      );
      // A rule key finds only that rule's issues.
      final byRule = ok(await repo.searchIssues(issue.rule!));
      expect(byRule.issues.every((i) => i.rule == issue.rule), isTrue);
      ok(await repo.fetchFileIssues(issue.component!));
      for (final metric in sonarQubeFileMetrics) {
        ok(await repo.fetchWorstFiles(project, metric));
      }
      final context = ok(await repo.fetchIssueContext(issue));
      expect(context.ruleName, isNotNull);
    }, skip: skip);

    test('hotspots', () async {
      final page = ok(await repo.fetchHotspots(project!));
      if (page.hotspots.isNotEmpty) {
        ok(await repo.fetchHotspotDetail(page.hotspots.first.key));
      }
      ok(await repo.fetchHotspots(project, reviewed: true));
    }, skip: skip);
  });

  group('writes (batch 7)', () {
    test('assign, transition, comment and back again', () async {
      final issue = ok(await repo.fetchIssues(project!)).issues.first;
      var detail = ok(await repo.fetchIssueDetail(issue.key));
      expect(detail.transitions, isNotEmpty);

      ok(await repo.assignIssue(issue.key, sonarQubeAssignToMe));
      detail = ok(await repo.fetchIssueDetail(issue.key));
      expect(detail.assignee, isNotNull);
      ok(await repo.assignIssue(issue.key, ''));
      expect(ok(await repo.fetchIssueDetail(issue.key)).assignee, isNull);

      ok(
        await repo.addIssueComment(
          issue.key,
          'JobTrigger live test & "quotes"? =x',
        ),
      );
      detail = ok(await repo.fetchIssueDetail(issue.key));
      expect(detail.comments.last.text, contains('& "quotes"? =x'));

      expect(detail.transitions, contains('confirm'));
      ok(await repo.transitionIssue(issue.key, 'confirm'));
      detail = ok(await repo.fetchIssueDetail(issue.key));
      expect(detail.status, 'CONFIRMED');
      expect(detail.transitions, contains('unconfirm'));
      ok(await repo.transitionIssue(issue.key, 'unconfirm'));
      expect(ok(await repo.fetchIssueDetail(issue.key)).status, 'REOPENED');

      // A transition the server does not offer is explained, not swallowed.
      final bad = await repo.transitionIssue(issue.key, 'nonsense');
      expect(bad, isA<Err<void, AppFailure>>());
      expect((bad as Err).error, isA<RejectedRequestFailure>());
    }, skip: skip);

    test('review a hotspot and put it back', () async {
      final page = ok(await repo.fetchHotspots(project!));
      if (page.hotspots.isEmpty) return;
      final key = page.hotspots.first.key;
      ok(
        await repo.reviewHotspot(
          key,
          SonarQubeHotspotReview.safe,
          comment: 'live test',
        ),
      );
      expect(
        ok(
          await repo.fetchHotspots(project, reviewed: true),
        ).hotspots.map((h) => h.key),
        contains(key),
      );
      ok(await repo.reviewHotspot(key, SonarQubeHotspotReview.toReview));
    }, skip: skip);

    test('an invalid token is an auth failure, not a permission one', () async {
      final bad = SonarQubeRepositoryImpl(
        buildSonarQubeDio(baseUrl: url!, token: 'invalid'),
      );
      final result = await bad.assignIssue('x', sonarQubeAssignToMe);
      expect((result as Err).error, isA<AuthFailure>());
    }, skip: skip);

    // Needs a second token whose user may browse the project but not
    // administer issues or hotspots (SONARQUBE_LIVE_READONLY_TOKEN).
    final readOnly = env['SONARQUBE_LIVE_READONLY_TOKEN'];
    test(
      'a read-only user can look, and every change is refused clearly',
      () async {
        final viewer = SonarQubeRepositoryImpl(
          buildSonarQubeDio(baseUrl: url!, token: readOnly),
        );
        final issue = ok(await viewer.fetchIssues(project!)).issues.first;
        ok(await viewer.fetchIssueDetail(issue.key));
        final hotspot = ok(await viewer.fetchHotspots(project)).hotspots.first;

        for (final denied in [
          await viewer.transitionIssue(issue.key, 'falsepositive'),
          await viewer.reviewHotspot(hotspot.key, SonarQubeHotspotReview.safe),
        ]) {
          expect((denied as Err).error, isA<SonarQubeWriteDeniedFailure>());
        }
        // ...and nothing changed.
        expect(
          ok(await viewer.fetchIssueDetail(issue.key)).status,
          isNot('RESOLVED'),
        );
      },
      skip: skip != false || readOnly == null
          ? 'needs SONARQUBE_LIVE_READONLY_TOKEN'
          : false,
    );
  });
}
