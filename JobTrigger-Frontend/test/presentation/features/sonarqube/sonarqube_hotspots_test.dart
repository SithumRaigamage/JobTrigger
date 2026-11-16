import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_hotspot.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue_grouping.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_hotspots_screen.dart';
import '../../../support/sonarqube_insights_defaults.dart';

const _open = SonarQubeHotspot(
  key: 'h1',
  message: 'Make sure this password is not hard-coded.',
  status: 'TO_REVIEW',
  securityCategory: 'weak-cryptography',
  vulnerabilityProbability: 'HIGH',
  file: 'src/config/auth.ts',
  line: 18,
);

const _reviewed = SonarQubeHotspot(
  key: 'h2',
  message: 'Make sure the permissive CORS header is intended.',
  status: 'REVIEWED',
  vulnerabilityProbability: 'MEDIUM',
  file: 'src/net/client.ts',
  line: 54,
);

class _Repo with SonarQubeInsightsDefaults implements SonarQubeRepository {
  String? lastStatus;
  int page = 1;

  @override
  Future<Result<SonarQubeHotspotPage, AppFailure>> fetchHotspots(
    String projectKey, {
    bool reviewed = false,
    int page = 1,
  }) async {
    lastStatus = reviewed ? 'REVIEWED' : 'TO_REVIEW';
    this.page = page;
    final hotspots = reviewed ? const [_reviewed] : const [_open];
    return Ok(SonarQubeHotspotPage(hotspots: hotspots, total: hotspots.length));
  }

  @override
  Future<Result<SonarQubeHotspotDetail, AppFailure>> fetchHotspotDetail(
    String hotspotKey,
  ) async => const Ok(
    SonarQubeHotspotDetail(
      ruleName: 'Hard-coded credentials',
      snippet: [SonarQubeSourceLine(number: 18, code: "const password = 'x';")],
    ),
  );

  // Only the hotspot reads matter here; the rest is the batch-1 interface.
  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
    SonarQubeIssueGrouping grouping = SonarQubeIssueGrouping.none,
  }) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeIssueContext, AppFailure>> fetchIssueContext(
    SonarQubeIssue issue,
  ) => throw UnimplementedError();

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) => throw UnimplementedError();
}

const _project = SonarQubeProject(
  key: 'acme:api',
  name: 'API Gateway',
  lastAnalysisDate: null,
);

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sonarQubeRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SonarQubeHotspotsScreen(project: _project),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('security hotspots (US-SQ-HOTSPOT-01)', () {
    testWidgets('lists the ones to review with category, place and '
        'probability spelled out', (tester) async {
      final repo = _Repo();
      await _pump(tester, repo);

      expect(find.text('Make sure this password is not hard-coded.'), findsOne);
      expect(find.text('weak-cryptography · src/config/auth.ts:18'), findsOne);
      expect(find.text('High probability'), findsOne);
      expect(repo.lastStatus, 'TO_REVIEW');
    });

    testWidgets('switching to Reviewed asks the server for those', (
      tester,
    ) async {
      final repo = _Repo();
      await _pump(tester, repo);

      await tester.tap(find.text('Reviewed'));
      await tester.pumpAndSettle();

      expect(repo.lastStatus, 'REVIEWED');
      expect(
        find.text('Make sure the permissive CORS header is intended.'),
        findsOne,
      );
      expect(find.text('Medium probability'), findsOne);
      expect(
        find.text('Make sure this password is not hard-coded.'),
        findsNothing,
      );
    });

    testWidgets('expanding a hotspot shows its rule and the code', (
      tester,
    ) async {
      await _pump(tester, _Repo());

      await tester.tap(find.text('Make sure this password is not hard-coded.'));
      await tester.pumpAndSettle();

      expect(find.text('Hard-coded credentials'), findsOne);
      expect(find.textContaining("const password = 'x';"), findsOne);
    });
  });
}
