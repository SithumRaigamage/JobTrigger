import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis_status.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_hotspot.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_measure_delta.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_branch_ref.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue_grouping.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_measure_history.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_worst_files.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_server_info.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body, {this.byPath = const {}});

  /// Answers for particular paths; anything else gets [body].
  final Map<String, dynamic> byPath;

  final int status;
  final dynamic body;
  RequestOptions? last;

  /// Every request made, oldest first: a method that looks up project names
  /// sends more than one, so the interesting call is not always [last].
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(byPath[options.path] ?? body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_Adapter a) =>
    Dio(BaseOptions(baseUrl: 'https://sonar.test'))..httpClientAdapter = a;

void main() {
  _batch1();
  _batch1Names();
  _issueSearch();
  _projectByKey();
  _hotspots();
  _history();
  _worstFiles();
  _issueGrouping();
  _branchRefs();
  _serverInfo();
  group('SonarQubeRepositoryImpl.fetchProjects (US-SQ-PROJ-01)', () {
    test('parses projects, including one that was never analysed', () async {
      final adapter = _Adapter(200, {
        'paging': {'pageIndex': 1, 'pageSize': 500, 'total': 2},
        'components': [
          {
            'key': 'acme:api',
            'name': 'API',
            'lastAnalysisDate': '2026-11-08T10:30:00+0000',
          },
          {'key': 'acme:web', 'name': 'Web'},
        ],
      });

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchProjects();

      final projects =
          (result as Ok<SonarQubeProjectsPage, AppFailure>).value.projects;
      expect(projects.map((p) => p.key), ['acme:api', 'acme:web']);
      expect(
        projects[0].lastAnalysisDate?.toUtc(),
        DateTime.utc(2026, 11, 8, 10, 30),
      );
      expect(projects[1].lastAnalysisDate, isNull);
    });

    test(
      'sends the organization on SonarCloud and none on self-hosted',
      () async {
        final cloud = _Adapter(200, {'components': <dynamic>[]});
        await SonarQubeRepositoryImpl(
          _dio(cloud),
          organization: ' acme-org ',
        ).fetchProjects();
        expect(cloud.last?.path, '/api/components/search_projects');
        expect(cloud.last?.queryParameters['organization'], 'acme-org');
        expect(cloud.last?.queryParameters['ps'], 500);

        final server = _Adapter(200, {'components': <dynamic>[]});
        await SonarQubeRepositoryImpl(_dio(server)).fetchProjects();
        expect(
          server.last?.queryParameters.containsKey('organization'),
          isFalse,
        );

        final blank = _Adapter(200, {'components': <dynamic>[]});
        await SonarQubeRepositoryImpl(
          _dio(blank),
          organization: '  ',
        ).fetchProjects();
        expect(
          blank.last?.queryParameters.containsKey('organization'),
          isFalse,
        );
      },
    );

    test('a 404 with an organization is a wrong organization key', () async {
      final result = await SonarQubeRepositoryImpl(
        _dio(_Adapter(404, {'errors': <dynamic>[]})),
        organization: 'nope',
      ).fetchProjects();

      final failure = (result as Err<SonarQubeProjectsPage, AppFailure>).error;
      expect(failure, isA<SonarQubeOrganizationNotFoundFailure>());
      expect(failure.message, contains('organization'));
    });

    test('a 404 without an organization is a plain not-found', () async {
      final result = await SonarQubeRepositoryImpl(
        _dio(_Adapter(404, <String, dynamic>{})),
      ).fetchProjects();

      expect(
        (result as Err<SonarQubeProjectsPage, AppFailure>).error,
        isA<NotFoundFailure>(),
      );
    });

    test(
      '401 stays an auth failure; 403 is SonarQube\'s own access-denied',
      () async {
        final unauthorized = await SonarQubeRepositoryImpl(
          _dio(_Adapter(401, <String, dynamic>{})),
        ).fetchProjects();
        expect(
          (unauthorized as Err<SonarQubeProjectsPage, AppFailure>).error,
          isA<AuthFailure>(),
        );
        final forbidden = await SonarQubeRepositoryImpl(
          _dio(_Adapter(403, <String, dynamic>{})),
        ).fetchProjects();
        expect(
          (forbidden as Err<SonarQubeProjectsPage, AppFailure>).error,
          isA<SonarQubeAccessDeniedFailure>(),
        );
      },
    );

    test(
      'a name-less project falls back to its key; a bad date is no date',
      () async {
        final result = await SonarQubeRepositoryImpl(
          _dio(
            _Adapter(200, {
              'components': [
                {'key': 'only-key', 'lastAnalysisDate': 'not a date'},
              ],
            }),
          ),
        ).fetchProjects();

        final p = (result as Ok<SonarQubeProjectsPage, AppFailure>)
            .value
            .projects
            .single;
        expect(p.name, 'only-key');
        expect(p.lastAnalysisDate, isNull);
      },
    );

    test('an HTML login page is an unexpected response, not a crash', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://sonar.test'))
        ..httpClientAdapter = _HtmlAdapter();

      final result = await SonarQubeRepositoryImpl(dio).fetchProjects();

      expect(
        (result as Err<SonarQubeProjectsPage, AppFailure>).error,
        isA<UnexpectedResponseFailure>(),
      );
    });
  });

  group('fetchQualityGate (US-SQ-QUALITY-01)', () {
    test('a failing gate lists its conditions', () async {
      final adapter = _Adapter(200, {
        'projectStatus': {
          'status': 'ERROR',
          'conditions': [
            {
              'status': 'ERROR',
              'metricKey': 'new_coverage',
              'comparator': 'LT',
              'errorThreshold': '80',
              'actualValue': '62.1',
            },
            {
              'status': 'OK',
              'metricKey': 'new_bugs',
              'comparator': 'GT',
              'errorThreshold': '0',
              'actualValue': '0',
            },
          ],
        },
      });

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
        organization: 'acme',
      ).fetchQualityGate('acme:api');

      expect(adapter.last?.path, '/api/qualitygates/project_status');
      expect(adapter.last?.queryParameters['projectKey'], 'acme:api');
      expect(
        adapter.last?.queryParameters.containsKey('organization'),
        isFalse,
      );
      final gate = (result as Ok<SonarQubeQualityGate, AppFailure>).value;
      expect(gate.state, QualityGateState.failed);
      expect(gate.conditions, hasLength(2));
      expect(gate.failing.single.metricKey, 'new_coverage');
      expect(gate.failing.single.actual, '62.1');
      expect(gate.failing.single.threshold, '80');
    });

    test('a project never analysed has no verdict', () async {
      final result = await SonarQubeRepositoryImpl(
        _dio(
          _Adapter(200, {
            'projectStatus': {'status': 'NONE', 'conditions': <dynamic>[]},
          }),
        ),
      ).fetchQualityGate('k');

      final gate = (result as Ok<SonarQubeQualityGate, AppFailure>).value;
      expect(gate.state, QualityGateState.none);
    });

    test('an unknown project says the project is gone', () async {
      final result = await SonarQubeRepositoryImpl(
        _dio(_Adapter(404, <String, dynamic>{})),
      ).fetchQualityGate('missing');

      expect(
        (result as Err<SonarQubeQualityGate, AppFailure>).error,
        isA<SonarQubeProjectNotFoundFailure>(),
      );
    });
  });

  group('fetchMeasures (US-SQ-QUALITY-02)', () {
    test('asks for the six measures and omits uncomputed ones', () async {
      final adapter = _Adapter(200, {
        'component': {
          'key': 'acme:api',
          'measures': [
            {'metric': 'bugs', 'value': '3'},
            {'metric': 'coverage', 'value': '71.4'},
            {'metric': 'ncloc', 'value': '12345'},
          ],
        },
      });

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchMeasures('acme:api');

      expect(adapter.last?.path, '/api/measures/component');
      expect(adapter.last?.queryParameters['component'], 'acme:api');
      expect(
        adapter.last?.queryParameters['metricKeys'],
        // The six headline measures, the ratings and the technical debt, then
        // the language distribution US-SQ-QUALITY-13 reads from the same call.
        'coverage,bugs,vulnerabilities,code_smells,duplicated_lines_density,'
        'ncloc,reliability_rating,security_rating,sqale_rating,sqale_index,'
        'ncloc_language_distribution',
      );
      final measures = (result as Ok<Map<String, String>, AppFailure>).value;
      expect(measures, {'bugs': '3', 'coverage': '71.4', 'ncloc': '12345'});
      expect(measures.containsKey('vulnerabilities'), isFalse);
    });
  });

  group('fetchIssues (US-SQ-QUALITY-03)', () {
    test(
      'filters and pages on the server and trims the project prefix',
      () async {
        final adapter = _Adapter(200, {
          'paging': {'pageIndex': 2, 'pageSize': 50, 'total': 73},
          'issues': [
            {
              'key': 'i1',
              'type': 'BUG',
              'severity': 'CRITICAL',
              'message': 'Null dereference',
              'component': 'acme:api:src/Foo.java',
              'line': 42,
            },
            {
              'key': 'i2',
              'type': 'CODE_SMELL',
              'severity': 'MINOR',
              'message': 'Rename this',
              'component': 'acme:api:src/Bar.java',
            },
            {
              'key': 'i3',
              'type': 'CODE_SMELL',
              'severity': 'INFO',
              'message': 'Project level',
              'component': 'acme:api',
            },
          ],
        });

        final result = await SonarQubeRepositoryImpl(_dio(adapter)).fetchIssues(
          'acme:api',
          filter: const SonarQubeIssueFilter(
            types: {'CODE_SMELL', 'BUG'},
            severities: {'MINOR', 'BLOCKER'},
          ),
          page: 2,
        );

        final q = adapter.last!.queryParameters;
        expect(adapter.last?.path, '/api/issues/search');
        expect(q['componentKeys'], 'acme:api');
        expect(q['resolved'], 'false');
        expect(q['ps'], 50);
        expect(q['p'], 2);
        // Sent in display order, whatever order they were picked in.
        expect(q['types'], 'BUG,CODE_SMELL');
        expect(q['severities'], 'BLOCKER,MINOR');
        final page = (result as Ok<SonarQubeIssuePage, AppFailure>).value;
        expect(page.total, 73);
        expect(page.issues[0].location, 'src/Foo.java:42');
        expect(page.issues[1].location, 'src/Bar.java');
        expect(page.issues[2].location, isNull);
      },
    );

    test('no filter sends no types or severities', () async {
      final adapter = _Adapter(200, {'issues': <dynamic>[]});

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchIssues('k');

      expect(adapter.last?.queryParameters.containsKey('types'), isFalse);
      expect(adapter.last?.queryParameters.containsKey('severities'), isFalse);
      expect(adapter.last?.queryParameters['p'], 1);
      final page = (result as Ok<SonarQubeIssuePage, AppFailure>).value;
      expect(page.issues, isEmpty);
      expect(page.total, 0);
    });
  });

  group('fetchAnalysisHistory (US-SQ-QUALITY-04)', () {
    test('parses analyses newest first, tolerating missing fields', () async {
      final adapter = _Adapter(200, {
        'paging': {'total': 3},
        'analyses': [
          {
            'key': 'a-old',
            'date': '2026-10-01T08:00:00+0000',
            'projectVersion': '1.0',
          },
          {
            'key': 'a-new',
            'date': '2026-11-08T10:00:00+0000',
            'projectVersion': '',
          },
          {'key': 'a-undated'},
        ],
      });

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchAnalysisHistory('acme:api');

      expect(adapter.last?.path, '/api/project_analyses/search');
      expect(adapter.last?.queryParameters['project'], 'acme:api');
      expect(adapter.last?.queryParameters['ps'], 50);
      final analyses =
          (result as Ok<List<SonarQubeAnalysis>, AppFailure>).value;
      expect(analyses.map((a) => a.key), ['a-new', 'a-old', 'a-undated']);
      expect(analyses[0].projectVersion, isNull);
      expect(analyses[1].projectVersion, '1.0');
      expect(analyses[2].date, isNull);
    });

    test('a project with no analyses is an empty list', () async {
      final result = await SonarQubeRepositoryImpl(
        _dio(_Adapter(200, {'analyses': <dynamic>[]})),
      ).fetchAnalysisHistory('k');

      expect(
        (result as Ok<List<SonarQubeAnalysis>, AppFailure>).value,
        isEmpty,
      );
    });
  });

  group('project list endpoint and fallback (A)', () {
    test(
      'uses search_projects, reads analysisDate and the paging total',
      () async {
        final adapter = _PathAdapter({
          '/api/components/search_projects': (
            200,
            {
              'paging': {'pageIndex': 2, 'pageSize': 500, 'total': 1203},
              'components': [
                {
                  'key': 'acme:api',
                  'name': 'API',
                  'analysisDate': '2026-11-08T10:30:00+0000',
                },
              ],
            },
          ),
        });
        final result = await SonarQubeRepositoryImpl(
          Dio(BaseOptions(baseUrl: 'https://sonar.test'))
            ..httpClientAdapter = adapter,
        ).fetchProjects(page: 2);

        final page = (result as Ok<SonarQubeProjectsPage, AppFailure>).value;
        expect(page.total, 1203);
        expect(
          page.projects.single.lastAnalysisDate?.toUtc(),
          DateTime.utc(2026, 11, 8, 10, 30),
        );
        expect(adapter.paths, ['/api/components/search_projects']);
        expect(adapter.queries.single['p'], 2);
        expect(adapter.queries.single['ps'], 500);
      },
    );

    test(
      'asks search_projects for the analysis date, and only that call',
      () async {
        final adapter = _PathAdapter({
          '/api/components/search_projects': (404, <String, dynamic>{}),
          '/api/projects/search': (200, {'components': <dynamic>[]}),
        });
        await SonarQubeRepositoryImpl(
          Dio(BaseOptions(baseUrl: 'https://sonar.test'))
            ..httpClientAdapter = adapter,
        ).fetchProjects();

        // The date is left out unless asked for (seen on a real server).
        expect(adapter.queries[0]['f'], 'analysisDate');
        // The fallback call already includes it and takes no such parameter.
        expect(adapter.queries[1].containsKey('f'), isFalse);
      },
    );

    for (final status in [404, 400]) {
      test('a server without search_projects ($status) falls back to the '
          'older call that already worked', () async {
        final adapter = _PathAdapter({
          '/api/components/search_projects': (status, <String, dynamic>{}),
          '/api/projects/search': (
            200,
            {
              'components': [
                {
                  'key': 'acme:web',
                  'name': 'Web',
                  'lastAnalysisDate': '2026-10-01T08:00:00+0000',
                },
              ],
            },
          ),
        });
        final result = await SonarQubeRepositoryImpl(
          Dio(BaseOptions(baseUrl: 'https://sonar.test'))
            ..httpClientAdapter = adapter,
        ).fetchProjects();

        final page = (result as Ok<SonarQubeProjectsPage, AppFailure>).value;
        expect(page.projects.single.key, 'acme:web');
        expect(page.projects.single.lastAnalysisDate, isNotNull);
        // No paging block: the total is what came back.
        expect(page.total, 1);
        expect(adapter.paths, [
          '/api/components/search_projects',
          '/api/projects/search',
        ]);
      });
    }

    test('a refusal (403) is final: the stricter call is not tried', () async {
      final adapter = _PathAdapter({
        '/api/components/search_projects': (403, <String, dynamic>{}),
      });
      final result = await SonarQubeRepositoryImpl(
        Dio(BaseOptions(baseUrl: 'https://sonar.test'))
          ..httpClientAdapter = adapter,
      ).fetchProjects();

      expect(
        (result as Err<SonarQubeProjectsPage, AppFailure>).error,
        isA<SonarQubeAccessDeniedFailure>(),
      );
      expect(adapter.paths, ['/api/components/search_projects']);
    });

    test('a wrong SonarCloud organization is reported, not retried', () async {
      final adapter = _PathAdapter({
        '/api/components/search_projects': (404, <String, dynamic>{}),
      });
      final result = await SonarQubeRepositoryImpl(
        Dio(BaseOptions(baseUrl: 'https://sonar.test'))
          ..httpClientAdapter = adapter,
        organization: 'nope',
      ).fetchProjects();

      expect(
        (result as Err<SonarQubeProjectsPage, AppFailure>).error,
        isA<SonarQubeOrganizationNotFoundFailure>(),
      );
      expect(adapter.paths, hasLength(1));
      expect(adapter.queries.single['organization'], 'nope');
    });

    test('both calls missing is a plain not-found', () async {
      final adapter = _PathAdapter({
        '/api/components/search_projects': (404, <String, dynamic>{}),
        '/api/projects/search': (404, <String, dynamic>{}),
      });
      final result = await SonarQubeRepositoryImpl(
        Dio(BaseOptions(baseUrl: 'https://sonar.test'))
          ..httpClientAdapter = adapter,
      ).fetchProjects();

      expect(
        (result as Err<SonarQubeProjectsPage, AppFailure>).error,
        isA<NotFoundFailure>(),
      );
    });
  });

  group('SonarQube-specific refusals on project calls (D)', () {
    SonarQubeRepositoryImpl repo(int status) => SonarQubeRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'https://sonar.test'))
        ..httpClientAdapter = _Adapter(status, <String, dynamic>{}),
    );

    test('403 on measures, issues and history is access-denied', () async {
      for (final result in [
        await repo(403).fetchMeasures('k'),
        await repo(403).fetchIssues('k'),
        await repo(403).fetchAnalysisHistory('k'),
        await repo(403).fetchQualityGate('k'),
      ]) {
        expect((result as Err).error, isA<SonarQubeAccessDeniedFailure>());
      }
    });

    test('404 on a project call says the project is gone', () async {
      for (final result in [
        await repo(404).fetchMeasures('k'),
        await repo(404).fetchAnalysisHistory('k'),
      ]) {
        expect((result as Err).error, isA<SonarQubeProjectNotFoundFailure>());
      }
    });

    test('other statuses keep the shared wording', () async {
      expect(
        (await repo(401).fetchMeasures('k') as Err).error,
        isA<AuthFailure>(),
      );
      expect(
        (await repo(500).fetchMeasures('k') as Err).error,
        isA<ServerFailure>(),
      );
    });
  });

  group('checkSonarQubeProjectAccess (B)', () {
    Dio dioFor(_PathAdapter a) =>
        Dio(BaseOptions(baseUrl: 'https://sonar.test'))..httpClientAdapter = a;

    test(
      'succeeds when one project can be listed, asking for just one',
      () async {
        final adapter = _PathAdapter({
          '/api/components/search_projects': (
            200,
            {
              'components': <dynamic>[],
              'paging': {'total': 0},
            },
          ),
        });

        final result = await checkSonarQubeProjectAccess(
          baseUrl: 'https://sonar.test',
          token: 't',
          organization: 'acme',
          dio: dioFor(adapter),
        );

        expect(result, isA<Ok<void, AppFailure>>());
        expect(adapter.queries.single['ps'], 1);
        expect(adapter.queries.single['organization'], 'acme');
      },
    );

    test('a valid token whose user may not browse says so', () async {
      final result = await checkSonarQubeProjectAccess(
        baseUrl: 'https://sonar.test',
        token: 't',
        dio: dioFor(
          _PathAdapter({
            '/api/components/search_projects': (403, <String, dynamic>{}),
          }),
        ),
      );

      final failure = (result as Err<void, AppFailure>).error;
      expect(failure, isA<SonarQubeAccessDeniedFailure>());
      expect(failure.message, contains('browse'));
    });
  });

  group('fetchProjectSummaries (US-SQ-PROJ-03)', () {
    Dio dioFor(_PathAdapter a) =>
        Dio(BaseOptions(baseUrl: 'https://sonar.test'))..httpClientAdapter = a;

    test('reads the gate and headline numbers per project', () async {
      final adapter = _PathAdapter({
        '/api/measures/search': (
          200,
          {
            'measures': [
              {'metric': 'alert_status', 'value': 'ERROR', 'component': 'a'},
              {'metric': 'bugs', 'value': '3', 'component': 'a'},
              {'metric': 'vulnerabilities', 'value': '1', 'component': 'a'},
              {'metric': 'code_smells', 'value': '20', 'component': 'a'},
              {'metric': 'coverage', 'value': '71.4', 'component': 'a'},
              {'metric': 'alert_status', 'value': 'OK', 'component': 'b'},
              {'metric': 'bugs', 'value': '0', 'component': 'b'},
            ],
          },
        ),
      });

      final result = await SonarQubeRepositoryImpl(
        dioFor(adapter),
      ).fetchProjectSummaries(['a', 'b', 'c']);

      final summaries =
          (result as Ok<Map<String, SonarQubeProjectSummary>, AppFailure>)
              .value;
      expect(summaries.keys, ['a', 'b', 'c']);
      expect(summaries['a']!.gate, QualityGateState.failed);
      expect(summaries['a']!.bugs, 3);
      expect(summaries['a']!.vulnerabilities, 1);
      expect(summaries['a']!.codeSmells, 20);
      expect(summaries['a']!.coverage, 71.4);
      expect(summaries['a']!.needsAttention, isTrue);
      expect(summaries['a']!.severityScore, 4);
      expect(summaries['b']!.gate, QualityGateState.passed);
      expect(summaries['b']!.codeSmells, isNull);
      expect(summaries['b']!.coverage, isNull);
      // No measures at all: not analysed, never an invented pass.
      expect(summaries['c']!.gate, QualityGateState.none);
      expect(summaries['c']!.isAnalysed, isFalse);
      expect(adapter.queries.single['projectKeys'], 'a,b,c');
      expect(
        adapter.queries.single['metricKeys'],
        'alert_status,bugs,vulnerabilities,code_smells,coverage',
      );
    });

    test('asks 100 projects at a time', () async {
      final adapter = _PathAdapter({
        '/api/measures/search': (200, {'measures': <dynamic>[]}),
      });
      final keys = [for (var i = 0; i < 250; i++) 'p$i'];

      final result = await SonarQubeRepositoryImpl(
        dioFor(adapter),
      ).fetchProjectSummaries(keys);

      expect(adapter.paths, hasLength(3));
      expect(
        adapter.queries.map(
          (q) => (q['projectKeys'] as String).split(',').length,
        ),
        containsAll([100, 50]),
      );
      expect(
        (result as Ok<Map<String, SonarQubeProjectSummary>, AppFailure>).value,
        hasLength(250),
      );
    });

    test('no keys means no request', () async {
      final adapter = _PathAdapter({});

      final result = await SonarQubeRepositoryImpl(
        dioFor(adapter),
      ).fetchProjectSummaries([]);

      expect(adapter.paths, isEmpty);
      expect(
        (result as Ok<Map<String, SonarQubeProjectSummary>, AppFailure>).value,
        isEmpty,
      );
    });

    test(
      'a refusal is access-denied; any failed batch fails the lot',
      () async {
        final result = await SonarQubeRepositoryImpl(
          dioFor(
            _PathAdapter({'/api/measures/search': (403, <String, dynamic>{})}),
          ),
        ).fetchProjectSummaries(['a']);

        expect(
          (result as Err<Map<String, SonarQubeProjectSummary>, AppFailure>)
              .error,
          isA<SonarQubeAccessDeniedFailure>(),
        );
      },
    );
  });

  group('issue details (US-SQ-QUALITY-06)', () {
    Dio dioFor(_PathAdapter a) =>
        Dio(BaseOptions(baseUrl: 'https://sonar.test'))..httpClientAdapter = a;

    const issue = SonarQubeIssue(
      key: 'AX-1',
      type: 'CODE_SMELL',
      severity: 'MAJOR',
      message: 'Remove this',
      file: 'src/Foo.java',
      line: 10,
      component: 'acme:src/Foo.java',
      rule: 'java:S1135',
    );

    test('fetchIssues carries the rule, effort, tags, author, status and '
        'date', () async {
      final adapter = _PathAdapter({
        '/api/issues/search': (
          200,
          {
            'paging': {'total': 1},
            'issues': [
              {
                'key': 'AX-1',
                'type': 'BUG',
                'severity': 'MAJOR',
                'message': 'm',
                'component': 'acme:src/Foo.java',
                'line': 10,
                'rule': 'java:S1135',
                'effort': '15min',
                'tags': ['cwe', 'security'],
                'author': 'dev@example.com',
                'status': 'OPEN',
                'creationDate': '2026-11-08T10:30:00+0000',
              },
            ],
          },
        ),
      });

      final result = await SonarQubeRepositoryImpl(
        dioFor(adapter),
      ).fetchIssues('acme');

      final got =
          (result as Ok<SonarQubeIssuePage, AppFailure>).value.issues.single;
      expect(got.rule, 'java:S1135');
      expect(got.effort, '15min');
      expect(got.tags, ['cwe', 'security']);
      expect(got.author, 'dev@example.com');
      expect(got.status, 'OPEN');
      expect(got.creationDate?.toUtc(), DateTime.utc(2026, 11, 8, 10, 30));
      expect(got.component, 'acme:src/Foo.java');
    });

    test(
      'the context has the rule name and plain code around the line',
      () async {
        final adapter = _PathAdapter({
          '/api/rules/show': (
            200,
            {
              'rule': {'key': 'java:S1135', 'name': 'Track uses of TODO tags'},
            },
          ),
          '/api/sources/show': (
            200,
            {
              'sources': [
                [8, '<span class="k">int</span> a = 1;'],
                [9, ''],
                [10, '<span class="k">if</span> (a &lt; b &amp;&amp; c) {'],
              ],
            },
          ),
        });

        final result = await SonarQubeRepositoryImpl(
          dioFor(adapter),
        ).fetchIssueContext(issue);

        final ctx = (result as Ok<SonarQubeIssueContext, AppFailure>).value;
        expect(ctx.ruleName, 'Track uses of TODO tags');
        expect(ctx.snippet.map((l) => l.number), [8, 9, 10]);
        expect(ctx.snippet[0].code, 'int a = 1;');
        expect(ctx.snippet[2].code, 'if (a < b && c) {');
        final source = adapter.paths.indexOf('/api/sources/show');
        expect(adapter.queries[source]['key'], 'acme:src/Foo.java');
        expect(adapter.queries[source]['from'], 6);
        expect(adapter.queries[source]['to'], 14);
      },
    );

    test('near the top of a file the snippet starts at line 1', () async {
      final adapter = _PathAdapter({
        '/api/rules/show': (200, {'rule': <String, dynamic>{}}),
        '/api/sources/show': (200, {'sources': <dynamic>[]}),
      });
      const early = SonarQubeIssue(
        key: 'k',
        type: 'BUG',
        severity: 'MAJOR',
        message: 'm',
        file: 'f',
        line: 2,
        component: 'p:f',
        rule: 'r',
      );

      await SonarQubeRepositoryImpl(dioFor(adapter)).fetchIssueContext(early);

      final source = adapter.paths.indexOf('/api/sources/show');
      expect(adapter.queries[source]['from'], 1);
    });

    test('one failing leaves the other', () async {
      final adapter = _PathAdapter({
        '/api/rules/show': (
          200,
          {
            'rule': {'name': 'Named'},
          },
        ),
        '/api/sources/show': (403, <String, dynamic>{}),
      });

      final result = await SonarQubeRepositoryImpl(
        dioFor(adapter),
      ).fetchIssueContext(issue);

      final ctx = (result as Ok<SonarQubeIssueContext, AppFailure>).value;
      expect(ctx.ruleName, 'Named');
      expect(ctx.snippet, isEmpty);
    });

    test('both failing is the failure', () async {
      final result = await SonarQubeRepositoryImpl(
        dioFor(
          _PathAdapter({
            '/api/rules/show': (403, <String, dynamic>{}),
            '/api/sources/show': (403, <String, dynamic>{}),
          }),
        ),
      ).fetchIssueContext(issue);

      expect(
        (result as Err<SonarQubeIssueContext, AppFailure>).error,
        isA<SonarQubeAccessDeniedFailure>(),
      );
    });

    test('an issue on a whole project (no line) asks for no code', () async {
      final adapter = _PathAdapter({
        '/api/rules/show': (
          200,
          {
            'rule': {'name': 'N'},
          },
        ),
      });
      const projectLevel = SonarQubeIssue(
        key: 'k',
        type: 'CODE_SMELL',
        severity: 'INFO',
        message: 'm',
        file: null,
        line: null,
        rule: 'r',
      );

      await SonarQubeRepositoryImpl(
        dioFor(adapter),
      ).fetchIssueContext(projectLevel);

      expect(adapter.paths, ['/api/rules/show']);
    });
  });
}

/// Answers per request path, so a call that falls back to another endpoint
/// can be scripted and its requests checked.
class _PathAdapter implements HttpClientAdapter {
  _PathAdapter(this.responses);

  final Map<String, (int, dynamic)> responses;
  final List<String> paths = [];
  final List<Map<String, dynamic>> queries = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    queries.add(options.queryParameters);
    final (status, body) =
        responses[options.path] ?? (404, <String, dynamic>{});
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _HtmlAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '<html>login</html>',
    200,
    headers: {
      Headers.contentTypeHeader: ['text/html'],
    },
  );

  @override
  void close({bool force = false}) {}
}

// P10-18 (batch 1): the four reads the project page and the cross-project
// issue list added — CE status, new-code measures, measure deltas, my issues.
void _batch1() {
  group('P10-18 insights', () {
    test(
      'parses the analysis status, its queue and a failure reason',
      () async {
        final adapter = _Adapter(200, {
          'current': {
            'status': 'FAILED',
            'type': 'REPORT',
            'submittedAt': '2026-11-12T13:00:00+0000',
            'executedAt': '2026-11-12T14:02:00+0000',
            'errorMessage': 'The main branch was not found',
          },
          'queue': [
            {'status': 'PENDING', 'type': 'REPORT'},
          ],
        });

        final result = await SonarQubeRepositoryImpl(
          _dio(adapter),
        ).fetchAnalysisStatus('acme:api');

        final status =
            (result as Ok<SonarQubeAnalysisStatus, AppFailure>).value;
        expect(status.current?.failed, isTrue);
        expect(
          status.lastFailure?.errorMessage,
          'The main branch was not found',
        );
        expect(status.queue.single.isQueued, isTrue);
        expect(adapter.last?.path, '/api/ce/component');
        expect(adapter.last?.queryParameters['component'], 'acme:api');
      },
    );

    test('asks for the new-code metrics and keeps what came back', () async {
      final adapter = _Adapter(200, {
        'component': {
          'measures': [
            {'metric': 'new_bugs', 'value': '1'},
            {'metric': 'new_lines', 'value': '620'},
          ],
        },
      });

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchNewCodeMeasures('acme:api');

      expect((result as Ok<Map<String, String>, AppFailure>).value, {
        'new_bugs': '1',
        'new_lines': '620',
      });
      expect(
        adapter.last?.queryParameters['metricKeys'],
        'new_bugs,new_vulnerabilities,new_code_smells,new_coverage,'
        'new_duplicated_lines_density,new_lines',
      );
    });

    test(
      'turns two history points into a delta, drops a single point',
      () async {
        final adapter = _Adapter(200, {
          'measures': [
            {
              'metric': 'bugs',
              'history': [
                {'date': '2026-11-12T10:00:00+0000', 'value': '3'},
                {'date': '2026-11-11T10:00:00+0000', 'value': '1'},
              ],
            },
            {
              'metric': 'coverage',
              'history': [
                {'date': '2026-11-12T10:00:00+0000', 'value': '62.3'},
              ],
            },
          ],
        });

        final result = await SonarQubeRepositoryImpl(
          _dio(adapter),
        ).fetchMeasureDeltas('acme:api', metricKeys: ['bugs', 'coverage']);

        final deltas =
            (result as Ok<List<SonarQubeMeasureDelta>, AppFailure>).value;
        expect(deltas, hasLength(1));
        expect(deltas.single.metricKey, 'bugs');
        expect(deltas.single.change, 2);
        expect(deltas.single.isWorse, isTrue);
        expect(adapter.last?.path, '/api/measures/search_history');
        expect(adapter.last?.queryParameters['ps'], 2);
      },
    );

    test('lists the caller\'s issues with no project filter', () async {
      final adapter = _Adapter(200, {
        'paging': {'total': 1},
        'issues': [
          {
            'key': 'i1',
            'type': 'BUG',
            'severity': 'MAJOR',
            'message': 'Handle the rejected promise',
            'component': 'acme:api:src/jobs/sync.ts',
            'project': 'acme:api',
            'line': 102,
            'status': 'OPEN',
          },
        ],
      });

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchMyIssues();

      final page = (result as Ok<SonarQubeIssuePage, AppFailure>).value;
      expect(page.issues.single.project, 'acme:api');
      // No name lookup answer here, so the row falls back to the key.
      expect(page.issues.single.projectLabel, 'acme:api');
      expect(page.issues.single.file, 'src/jobs/sync.ts');
      expect(page.issues.single.line, 102);

      final search = adapter.requests.first;
      expect(search.path, '/api/issues/search');
      expect(search.queryParameters['assignees'], '__me__');
      expect(search.queryParameters['resolved'], 'false');
      expect(search.queryParameters.containsKey('componentKeys'), isFalse);
    });
  });
}

// US-SQ-ISSUES-03: api/issues/search has no free-text `q` (verified on a real
// SonarQube 26.1), so each search field maps to the filter the server has.
void _issueSearch() {
  for (final entry in {
    SonarQubeIssueSearchField.rule: 'rules',
    SonarQubeIssueSearchField.tag: 'tags',
    SonarQubeIssueSearchField.file: 'files',
    SonarQubeIssueSearchField.issueKey: 'issues',
  }.entries) {
    test(
      '${entry.key.label} searches with ${entry.value}, no project',
      () async {
        final adapter = _Adapter(200, {
          'paging': {'total': 0},
          'issues': <dynamic>[],
        });

        final result = await SonarQubeRepositoryImpl(
          _dio(adapter),
        ).searchIssues('  term  ', field: entry.key, page: 2);

        expect(result, isA<Ok<SonarQubeIssuePage, AppFailure>>());
        final query = adapter.requests.first.queryParameters;
        expect(adapter.requests.first.path, '/api/issues/search');
        expect(query[entry.value], 'term');
        expect(query['p'], 2);
        expect(query['resolved'], 'false');
        expect(query.containsKey('q'), isFalse);
        expect(query.containsKey('assignees'), isFalse);
        expect(query.containsKey('componentKeys'), isFalse);
      },
    );
  }
}

// US-SQ-LINK-02: a project link looks the project up by key, and only a
// project (a real SonarQube 26.1 answers `TRK`) may be opened that way.
void _projectByKey() {
  test('fetchProjectByKey reads a project from components/show', () async {
    final adapter = _Adapter(200, {
      'component': {
        'key': 'jt-sample',
        'name': 'JT Sample',
        'qualifier': 'TRK',
        'analysisDate': '2026-11-17T06:29:01+0000',
      },
    });
    final result = await SonarQubeRepositoryImpl(
      _dio(adapter),
    ).fetchProjectByKey('jt-sample');
    final project = (result as Ok<SonarQubeProject, AppFailure>).value;
    expect(project.name, 'JT Sample');
    expect(project.lastAnalysisDate, isNotNull);
    expect(adapter.requests.single.path, '/api/components/show');
    expect(adapter.requests.single.queryParameters['component'], 'jt-sample');
  });

  test('a file key is not a project', () async {
    final adapter = _Adapter(200, {
      'component': {'key': 'jt-sample:src/app.js', 'qualifier': 'FIL'},
    });
    final result = await SonarQubeRepositoryImpl(
      _dio(adapter),
    ).fetchProjectByKey('jt-sample:src/app.js');
    expect(
      (result as Err<SonarQubeProject, AppFailure>).error,
      isA<SonarQubeProjectNotFoundFailure>(),
    );
  });

  test('an unknown key is project-not-found', () async {
    final adapter = _Adapter(404, <String, dynamic>{});
    final result = await SonarQubeRepositoryImpl(
      _dio(adapter),
    ).fetchProjectByKey('nope');
    expect(
      (result as Err<SonarQubeProject, AppFailure>).error,
      isA<SonarQubeProjectNotFoundFailure>(),
    );
  });
}

// P10-18 leftovers: the cross-project list names its projects in one request
// (or none, when the names are already cached), never one per project.
void _batch1Names() {
  test('names the projects of my issues in one request', () async {
    final adapter = _Adapter(
      200,
      {
        'paging': {'total': 2},
        'issues': [
          {
            'key': 'i1',
            'type': 'BUG',
            'severity': 'MAJOR',
            'message': 'A',
            'company': null,
            'project': 'acme:api',
            'component': 'acme:api:src/a.ts',
          },
          {
            'key': 'i2',
            'type': 'BUG',
            'severity': 'MINOR',
            'message': 'B',
            'project': 'acme:web',
            'component': 'acme:web:src/b.ts',
          },
        ],
      },
      byPath: {
        '/api/components/search_projects': {
          'components': [
            {'key': 'acme:api', 'name': 'API Gateway'},
            {'key': 'acme:web', 'name': 'Website'},
          ],
        },
      },
    );

    final repo = SonarQubeRepositoryImpl(_dio(adapter));
    final first = await repo.fetchMyIssues();
    final page = (first as Ok<SonarQubeIssuePage, AppFailure>).value;

    expect(page.issues.map((i) => i.projectLabel), ['API Gateway', 'Website']);
    // One issues call and one name lookup for the whole page.
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.last.path, '/api/components/search_projects');
    expect(
      adapter.requests.last.queryParameters['projects'] as String,
      allOf(contains('acme:api'), contains('acme:web')),
    );

    // Names are cached: a second page costs the issues call only.
    adapter.requests.clear();
    await repo.fetchMyIssues(page: 2);
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.path, '/api/issues/search');
  });
}

// US-SQ-HOTSPOT-01: the hotspot list and its expanded detail.
void _hotspots() {
  group('hotspots (US-SQ-HOTSPOT-01)', () {
    test('asks for the to-review ones by default and parses them', () async {
      final adapter = _Adapter(200, {
        'paging': {'total': 1},
        'hotspots': [
          {
            'key': 'h1',
            'message': 'Make sure this password is not hard-coded.',
            'status': 'TO_REVIEW',
            'securityCategory': 'weak-cryptography',
            'vulnerabilityProbability': 'HIGH',
            'component': 'acme:api:src/config/auth.ts',
            'line': 18,
          },
        ],
      });

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchHotspots('acme:api');

      final page = (result as Ok<SonarQubeHotspotPage, AppFailure>).value;
      expect(page.hotspots.single.file, 'src/config/auth.ts');
      expect(page.hotspots.single.location, 'src/config/auth.ts:18');
      expect(page.hotspots.single.probabilityLabel, 'High probability');
      expect(adapter.last?.path, '/api/hotspots/search');
      expect(adapter.last?.queryParameters['status'], 'TO_REVIEW');

      await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchHotspots('acme:api', reviewed: true);
      expect(adapter.last?.queryParameters['status'], 'REVIEWED');
    });

    test('reads the rule and the code around a hotspot', () async {
      final adapter = _Adapter(
        200,
        {
          'hotspot': {
            'rule': {'name': 'Hard-coded credentials'},
            'component': {'key': 'acme:api:src/config/auth.ts'},
            'textRange': {'startLine': 18},
          },
        },
        byPath: {
          '/api/sources/show': {
            // SonarQube sends each line as a [number, html] pair.
            'sources': [
              [18, 'const password = &#39;x&#39;;'],
            ],
          },
        },
      );

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchHotspotDetail('h1');

      final detail = (result as Ok<SonarQubeHotspotDetail, AppFailure>).value;
      expect(detail.ruleName, 'Hard-coded credentials');
      expect(detail.snippet.single.number, 18);
      expect(detail.snippet.single.code, "const password = 'x';");
    });
  });
}

// US-SQ-QUALITY-11: history points, oldest first, blanks dropped.
void _history() {
  group('measure history (US-SQ-QUALITY-11)', () {
    test('parses the points, drops valueless ones and sorts by date', () async {
      final adapter = _Adapter(200, {
        'measures': [
          {
            'metric': 'coverage',
            'history': [
              {'date': '2026-11-01T10:00:00+0000', 'value': '69.2'},
              {'date': '2026-10-15T10:00:00+0000'},
              {'date': '2026-10-01T10:00:00+0000', 'value': '71.0'},
            ],
          },
        ],
      });

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchMeasureHistory('acme:api', 'coverage');

      final history = (result as Ok<SonarQubeMeasureHistory, AppFailure>).value;
      expect(history.points.map((p) => p.value), [71, 69.2]);
      expect(
        history.points.first.date.isBefore(history.points.last.date),
        isTrue,
      );
      expect(history.unit, '%');
      expect(adapter.last?.path, '/api/measures/search_history');
      expect(adapter.last?.queryParameters['component'], 'acme:api');
      expect(adapter.last?.queryParameters['metrics'], 'coverage');
    });

    test(
      'a project without history is an empty history, not an error',
      () async {
        final result = await SonarQubeRepositoryImpl(
          _dio(_Adapter(200, {'measures': <Object>[]})),
        ).fetchMeasureHistory('acme:api', 'bugs');

        final history =
            (result as Ok<SonarQubeMeasureHistory, AppFailure>).value;
        expect(history.points, isEmpty);
        expect(history.hasEnoughHistory, isFalse);
      },
    );
  });
}

// US-SQ-QUALITY-12: the ten worst files, ranked on the server.
void _worstFiles() {
  group('worst files (US-SQ-QUALITY-12)', () {
    test('asks the server for file leaves sorted the metric way', () async {
      final adapter = _Adapter(200, {
        'components': [
          {
            'key': 'acme:api:src/legacy/report.ts',
            'measures': [
              {'metric': 'coverage', 'value': '0.0'},
            ],
          },
          {'key': 'acme:api:src/net/client.ts'},
        ],
      });

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchWorstFiles('acme:api', sonarQubeFileMetrics.first);

      final files = (result as Ok<SonarQubeWorstFiles, AppFailure>).value;
      expect(adapter.last?.path, '/api/measures/component_tree');
      expect(adapter.last?.queryParameters['qualifiers'], 'FIL');
      expect(adapter.last?.queryParameters['strategy'], 'leaves');
      expect(adapter.last?.queryParameters['metricSort'], 'coverage');
      expect(adapter.last?.queryParameters['asc'], true);
      expect(files.files.first.path, 'src/legacy/report.ts');
      expect(files.format(files.files.first.value), '0%');
      // A file the server sent without a value is a dash, not a zero.
      expect(files.format(files.files.last.value), '—');
    });

    test('the duplication ranking sorts the other way', () async {
      final adapter = _Adapter(200, {'components': <Object>[]});
      final metric = sonarQubeFileMetrics.firstWhere(
        (m) => m.metric == 'duplicated_lines_density',
      );

      await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchWorstFiles('acme:api', metric);

      expect(adapter.last?.queryParameters['asc'], false);
    });
  });
}

// US-SQ-ISSUES-02: grouping rides on the server's facets.
void _issueGrouping() {
  group('issue grouping (US-SQ-ISSUES-02)', () {
    test('asks for the facet and reads the server counts', () async {
      final adapter = _Adapter(200, {
        'total': 9,
        'issues': <Object>[],
        'facets': [
          {
            'property': 'severities',
            'values': [
              {'val': 'MAJOR', 'count': 6},
              {'val': 'MINOR', 'count': 3},
            ],
          },
        ],
      });

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchIssues('acme:api', grouping: SonarQubeIssueGrouping.severity);

      final page = (result as Ok<SonarQubeIssuePage, AppFailure>).value;
      expect(adapter.last?.queryParameters['facets'], 'severities');
      expect(page.groups.map((g) => g.label), ['MAJOR', 'MINOR']);
      expect(page.groups.first.count, 6);
    });

    test('without grouping no facet is asked for', () async {
      final adapter = _Adapter(200, {'total': 0, 'issues': <Object>[]});
      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchIssues('acme:api');

      expect(adapter.last?.queryParameters.containsKey('facets'), isFalse);
      expect(
        (result as Ok<SonarQubeIssuePage, AppFailure>).value.groups,
        isEmpty,
      );
    });
  });
}

// US-SQ-QUALITY-10: the branch and pull-request choices.
void _branchRefs() {
  group('branch refs (US-SQ-QUALITY-10)', () {
    test('merges branches and pull requests, main excluded', () async {
      final adapter = _Adapter(
        200,
        {
          'branches': [
            {'name': 'main', 'isMain': true},
          ],
        },
        byPath: {
          '/api/project_branches/list': {
            'branches': [
              {'name': 'main', 'isMain': true},
              {'name': 'release/2.0', 'isMain': false},
            ],
          },
          '/api/project_pull_requests/list': {
            'pullRequests': [
              {'key': '7', 'title': 'Retry'},
            ],
          },
        },
      );

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchProjectRefs('acme:api');

      final choices = (result as Ok<SonarQubeRefChoices, AppFailure>).value;
      expect(choices.hasChoice, isTrue);
      expect(choices.refs.map((r) => r.label), ['release/2.0', 'PR 7']);
    });

    test('a server without those endpoints offers no choice', () async {
      final adapter = _Adapter(404, {'errors': <Object>[]});

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchProjectRefs('acme:api');

      final choices = (result as Ok<SonarQubeRefChoices, AppFailure>).value;
      expect(choices.hasChoice, isFalse);
    });
  });
}

// US-SQ-SERVER-01: version and status from the two public endpoints.
void _serverInfo() {
  group('server info (US-SQ-SERVER-01)', () {
    test('reads the version string and the status', () async {
      final adapter = _Adapter(
        200,
        '10.6.0.92116',
        byPath: {
          '/api/server/version': '10.6.0.92116',
          '/api/system/status': {'status': 'UP'},
        },
      );

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchServerInfo();

      final info = (result as Ok<SonarQubeServerInfo, AppFailure>).value;
      expect(info.version, '10.6.0.92116');
      expect(info.statusLabel, 'Up');
      expect(info.isUp, isTrue);
    });

    test('a starting server keeps its own word and says why', () async {
      final adapter = _Adapter(
        200,
        {'status': 'STARTING'},
        byPath: {
          '/api/server/version': '10.6.0.92116',
          '/api/system/status': {'status': 'STARTING'},
        },
      );

      final result = await SonarQubeRepositoryImpl(
        _dio(adapter),
      ).fetchServerInfo();

      final info = (result as Ok<SonarQubeServerInfo, AppFailure>).value;
      expect(info.isUp, isFalse);
      expect(info.hint, contains('starting'));
    });
  });
}
