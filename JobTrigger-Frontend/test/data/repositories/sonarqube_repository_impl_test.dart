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

      final projects = (result as Ok<List<SonarQubeProject>, AppFailure>).value;
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
        expect(cloud.last?.path, '/api/projects/search');
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

      final failure = (result as Err<List<SonarQubeProject>, AppFailure>).error;
      expect(failure, isA<SonarQubeOrganizationNotFoundFailure>());
      expect(failure.message, contains('organization'));
    });

    test('a 404 without an organization is a plain not-found', () async {
      final result = await SonarQubeRepositoryImpl(
        _dio(_Adapter(404, <String, dynamic>{})),
      ).fetchProjects();

      expect(
        (result as Err<List<SonarQubeProject>, AppFailure>).error,
        isA<NotFoundFailure>(),
      );
    });

    test('401 and 403 keep their usual meanings', () async {
      final unauthorized = await SonarQubeRepositoryImpl(
        _dio(_Adapter(401, <String, dynamic>{})),
      ).fetchProjects();
      expect(
        (unauthorized as Err<List<SonarQubeProject>, AppFailure>).error,
        isA<AuthFailure>(),
      );
      final forbidden = await SonarQubeRepositoryImpl(
        _dio(_Adapter(403, <String, dynamic>{})),
      ).fetchProjects();
      expect(
        (forbidden as Err<List<SonarQubeProject>, AppFailure>).error,
        isA<PermissionFailure>(),
      );
    });

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

        final p =
            (result as Ok<List<SonarQubeProject>, AppFailure>).value.single;
        expect(p.name, 'only-key');
        expect(p.lastAnalysisDate, isNull);
      },
    );

    test('an HTML login page is an unexpected response, not a crash', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://sonar.test'))
        ..httpClientAdapter = _HtmlAdapter();

      final result = await SonarQubeRepositoryImpl(dio).fetchProjects();

      expect(
        (result as Err<List<SonarQubeProject>, AppFailure>).error,
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

    test('an unknown project is a not-found', () async {
      final result = await SonarQubeRepositoryImpl(
        _dio(_Adapter(404, <String, dynamic>{})),
      ).fetchQualityGate('missing');

      expect(
        (result as Err<SonarQubeQualityGate, AppFailure>).error,
        isA<NotFoundFailure>(),
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
