import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';

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
