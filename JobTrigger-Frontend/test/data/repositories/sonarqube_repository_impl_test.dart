import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);

  final int status;
  final dynamic body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
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

Dio _dio(_Adapter a) =>
    Dio(BaseOptions(baseUrl: 'https://sonar.test'))..httpClientAdapter = a;

void main() {
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
        'coverage,bugs,vulnerabilities,code_smells,duplicated_lines_density,ncloc',
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
