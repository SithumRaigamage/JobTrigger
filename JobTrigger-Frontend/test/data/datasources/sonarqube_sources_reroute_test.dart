import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/datasources/sonarqube_client_factory.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_branch_ref.dart';

/// Answers every request with [body] and remembers what was asked.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.body);
  final Map<String, dynamic> body;
  final seen = <Uri>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options.uri);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  // Open question from P10-21/22: does api/sources/show take a branch? It does
  // not (SonarQube 26.1 web-service listing: key, from, to), but
  // api/sources/lines does, so a chosen ref reroutes the lookup.
  group('source lookups follow the chosen ref', () {
    test('a branch reroutes show to lines and keeps the pair shape', () async {
      final adapter = _Adapter({
        'sources': [
          {'line': 4, 'code': 'a'},
          {'line': 5, 'code': 'b'},
        ],
      });
      final dio = buildSonarQubeDio(
        baseUrl: 'https://sonar.test',
        token: 't',
        refFor: (key) => key == 'web'
            ? const SonarQubeBranchRef.branch('feature/login')
            : const SonarQubeBranchRef.main(),
      )..httpClientAdapter = adapter;

      final response = await dio.get<Map<String, dynamic>>(
        '/api/sources/show',
        queryParameters: {'key': 'web:src/app.ts', 'from': 4, 'to': 5},
      );

      expect(adapter.seen.single.path, '/api/sources/lines');
      expect(adapter.seen.single.queryParameters['branch'], 'feature/login');
      expect(response.data!['sources'], [
        [4, 'a'],
        [5, 'b'],
      ]);
    });

    test('a pull request is sent as pullRequest', () async {
      final adapter = _Adapter({'sources': <dynamic>[]});
      final dio = buildSonarQubeDio(
        baseUrl: 'https://sonar.test',
        token: 't',
        refFor: (_) => const SonarQubeBranchRef.pullRequest('42'),
      )..httpClientAdapter = adapter;

      await dio.get<Map<String, dynamic>>(
        '/api/sources/show',
        queryParameters: {'key': 'web:a.ts', 'from': 1, 'to': 2},
      );

      expect(adapter.seen.single.path, '/api/sources/lines');
      expect(adapter.seen.single.queryParameters['pullRequest'], '42');
    });

    test('on the main branch show is left exactly as it was', () async {
      final adapter = _Adapter({
        'sources': [
          [1, 'x'],
        ],
      });
      final dio = buildSonarQubeDio(
        baseUrl: 'https://sonar.test',
        token: 't',
        refFor: (_) => const SonarQubeBranchRef.main(),
      )..httpClientAdapter = adapter;

      final response = await dio.get<Map<String, dynamic>>(
        '/api/sources/show',
        queryParameters: {'key': 'web:a.ts', 'from': 1, 'to': 2},
      );

      expect(adapter.seen.single.path, '/api/sources/show');
      expect(adapter.seen.single.queryParameters.containsKey('branch'), false);
      expect(response.data!['sources'], [
        [1, 'x'],
      ]);
    });
  });
}
