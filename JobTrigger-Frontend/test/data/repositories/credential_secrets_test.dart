import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/storage/secure_storage_service.dart';
import 'package:job_trigger/data/credentials/credential_secrets.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/github_credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/sonarqube_credentials_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// E4 (PE-32, PE-34): the backend's lists carry a mask and no secret; the
/// app fetches each secret from `GET …/:id/secret`, keeps it in secure
/// storage only, and asks again when the credential was saved since.
class _Backend implements HttpClientAdapter {
  _Backend(this.routes);

  /// "METHOD path" → (status, body).
  final Map<String, (int, Object?)> routes;
  final requests = <String>[];

  int count(String suffix) =>
      requests.where((request) => request.endsWith(suffix)).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    requests.add(key);
    final (status, body) = routes[key] ?? (404, {'message': 'no route'});
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

const _t1 = '2026-11-14T10:00:00.000Z';
const _t2 = '2026-11-14T11:00:00.000Z';

/// What each tool needs to be driven the same way.
class _Tool {
  const _Tool({
    required this.name,
    required this.path,
    required this.listRow,
    required this.secretBody,
    required this.secretValue,
    required this.build,
    required this.fetchAll,
    required this.add,
    required this.delete,
    required this.secretOf,
  });

  final String name;
  final String path;
  final Map<String, Object?> Function(String updatedAt, {bool reentry}) listRow;
  final Map<String, Object?> Function(String version) secretBody;
  final String secretValue;
  final Object Function(Dio, CredentialSecrets) build;
  final Future<Result<List<Object>, Object>> Function(Object repo) fetchAll;
  final Future<Result<Object, Object>> Function(Object repo) add;
  final Future<Result<void, Object>> Function(Object repo) delete;
  final String? Function(Object entity) secretOf;
}

final _tools = [
  _Tool(
    name: 'jenkins',
    path: '/api/credentials',
    listRow: (updatedAt, {reentry = false}) => {
      '_id': 'c1',
      'serverName': 'Jenkins',
      'jenkinsURL': 'https://j.test',
      'username': 'u',
      'secretMask': reentry ? null : '••••1234',
      'hasParamToken': true,
      'needsReentry': reentry,
      'isDefault': true,
      'updatedAt': updatedAt,
    },
    secretBody: (version) => {
      'password': 'jenkins-pass-1234',
      'paramToken': 'trigger-1',
      'needsReentry': false,
      'version': version,
    },
    secretValue: 'jenkins-pass-1234',
    build: (dio, secrets) => CredentialsRepositoryImpl(dio, secrets),
    fetchAll: (r) async =>
        (await (r as CredentialsRepositoryImpl).fetchAll()).map(List.of),
    add: (r) => (r as CredentialsRepositoryImpl).add(
      serverName: 'Jenkins',
      jenkinsURL: 'https://j.test',
      username: 'u',
      secret: 'typed-secret',
    ),
    delete: (r) => (r as CredentialsRepositoryImpl).delete('c1'),
    secretOf: (e) => (e as dynamic).secret as String?,
  ),
  _Tool(
    name: 'github',
    path: '/api/github-credentials',
    listRow: (updatedAt, {reentry = false}) => {
      '_id': 'c1',
      'label': 'GitHub',
      'secretMask': reentry ? null : '••••1234',
      'needsReentry': reentry,
      'isDefault': true,
      'updatedAt': updatedAt,
    },
    secretBody: (version) => {
      'token': 'ghp_token_1234',
      'needsReentry': false,
      'version': version,
    },
    secretValue: 'ghp_token_1234',
    build: (dio, secrets) => GitHubCredentialsRepositoryImpl(dio, secrets),
    fetchAll: (r) async =>
        (await (r as GitHubCredentialsRepositoryImpl).fetchAll()).map(List.of),
    add: (r) => (r as GitHubCredentialsRepositoryImpl).add(
      label: 'GitHub',
      secret: 'typed-secret',
    ),
    delete: (r) => (r as GitHubCredentialsRepositoryImpl).delete('c1'),
    secretOf: (e) => (e as dynamic).secret as String?,
  ),
  _Tool(
    name: 'sonarqube',
    path: '/api/sonarqube-credentials',
    listRow: (updatedAt, {reentry = false}) => {
      '_id': 'c1',
      'label': 'Sonar',
      'baseUrl': 'https://sonar.test',
      'secretMask': reentry ? null : '••••1234',
      'needsReentry': reentry,
      'isDefault': true,
      'updatedAt': updatedAt,
    },
    secretBody: (version) => {
      'token': 'sq_token_1234',
      'needsReentry': false,
      'version': version,
    },
    secretValue: 'sq_token_1234',
    build: (dio, secrets) => SonarQubeCredentialsRepositoryImpl(dio, secrets),
    fetchAll: (r) async =>
        (await (r as SonarQubeCredentialsRepositoryImpl).fetchAll()).map(
          List.of,
        ),
    add: (r) => (r as SonarQubeCredentialsRepositoryImpl).add(
      label: 'Sonar',
      baseUrl: 'https://sonar.test',
      secret: 'typed-secret',
    ),
    delete: (r) => (r as SonarQubeCredentialsRepositoryImpl).delete('c1'),
    secretOf: (e) => (e as dynamic).secret as String?,
  ),
];

void main() {
  for (final tool in _tools) {
    group('${tool.name} credentials (E4)', () {
      late FlutterSecureStorage storage;
      late SecureStorageService service;

      setUp(() {
        FlutterSecureStorage.setMockInitialValues({});
        storage = const FlutterSecureStorage();
        service = SecureStorageService(storage);
      });

      ({_Backend backend, Object repo}) make(
        Map<String, (int, Object?)> routes,
      ) {
        final backend = _Backend(routes);
        final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = backend;
        return (
          backend: backend,
          repo: tool.build(dio, CredentialSecrets(dio, service)),
        );
      }

      test('fetches the secret once, stores it, and reuses it', () async {
        final (:backend, :repo) = make({
          'GET ${tool.path}': (200, [tool.listRow(_t1)]),
          'GET ${tool.path}/c1/secret': (200, tool.secretBody(_t1)),
        });

        final first = (await tool.fetchAll(repo) as Ok).value as List;
        expect(tool.secretOf(first.single as Object), tool.secretValue);
        expect(backend.count('/c1/secret'), 1);

        // The secret is on the device in secure storage, under one key.
        final stored = await storage.readAll();
        expect(stored.keys, ['credential_secret_${tool.name}_c1']);
        expect(stored.values.single, contains(tool.secretValue));

        final second = (await tool.fetchAll(repo) as Ok).value as List;
        expect(tool.secretOf(second.single as Object), tool.secretValue);
        expect(backend.count('/c1/secret'), 1, reason: 'served from storage');
      });

      test('fetches again once the credential was saved since', () async {
        final (:backend, :repo) = make({
          'GET ${tool.path}': (200, [tool.listRow(_t1)]),
          'GET ${tool.path}/c1/secret': (200, tool.secretBody(_t1)),
        });
        await tool.fetchAll(repo);

        backend.routes['GET ${tool.path}'] = (200, [tool.listRow(_t2)]);
        backend.routes['GET ${tool.path}/c1/secret'] = (
          200,
          tool.secretBody(_t2),
        );
        await tool.fetchAll(repo);

        expect(backend.count('/c1/secret'), 2);
      });

      test('does not ask for a secret the server could not read', () async {
        final (:backend, :repo) = make({
          'GET ${tool.path}': (200, [tool.listRow(_t1, reentry: true)]),
        });

        final list = (await tool.fetchAll(repo) as Ok).value as List;

        expect(backend.count('/c1/secret'), 0);
        expect(tool.secretOf(list.single as Object), isNull);
        expect((list.single as dynamic).needsReentry, isTrue);
      });

      test('one failed secret request does not fail the list', () async {
        final (:backend, :repo) = make({
          'GET ${tool.path}': (200, [tool.listRow(_t1)]),
          'GET ${tool.path}/c1/secret': (500, {'message': 'boom'}),
        });

        final result = await tool.fetchAll(repo);

        expect(result, isA<Ok<List<Object>, Object>>());
        final list = (result as Ok).value as List;
        expect(tool.secretOf(list.single as Object), isNull);
        // Not "re-enter it": the server read it fine, the app just couldn't ask.
        expect((list.single as dynamic).needsReentry, isFalse);
        expect(await storage.readAll(), isEmpty);
      });

      test(
        'saving keeps the typed secret, so the next load needs no fetch',
        () async {
          final (:backend, :repo) = make({
            'POST ${tool.path}': (201, tool.listRow(_t1)),
            'GET ${tool.path}': (200, [tool.listRow(_t1)]),
          });

          final added = (await tool.add(repo) as Ok).value as Object;
          expect(tool.secretOf(added), 'typed-secret');
          final list = (await tool.fetchAll(repo) as Ok).value as List;

          expect(tool.secretOf(list.single as Object), 'typed-secret');
          expect(backend.count('/c1/secret'), 0);
        },
      );

      test('deleting drops the stored secret', () async {
        final (:backend, :repo) = make({
          'GET ${tool.path}': (200, [tool.listRow(_t1)]),
          'GET ${tool.path}/c1/secret': (200, tool.secretBody(_t1)),
          'DELETE ${tool.path}/c1': (200, {'message': 'Credential removed'}),
        });
        await tool.fetchAll(repo);
        expect(await storage.readAll(), isNotEmpty);

        await tool.delete(repo);

        expect(await storage.readAll(), isEmpty);
      });

      test('logging out clears every stored secret', () async {
        final (:backend, :repo) = make({
          'GET ${tool.path}': (200, [tool.listRow(_t1)]),
          'GET ${tool.path}/c1/secret': (200, tool.secretBody(_t1)),
        });
        await tool.fetchAll(repo);
        expect(await storage.readAll(), isNotEmpty);

        await service.clear(); // What AuthNotifier's logout calls.

        expect(await storage.readAll(), isEmpty);
      });

      test('never keeps a secret outside secure storage', () async {
        final (:backend, :repo) = make({
          'GET ${tool.path}': (200, [tool.listRow(_t1)]),
          'GET ${tool.path}/c1/secret': (200, tool.secretBody(_t1)),
        });
        await tool.fetchAll(repo);

        // shared_preferences (the other store the app uses) stays empty.
        final prefs = await _prefsDump();
        expect(prefs, isNot(contains(tool.secretValue)));
      });
    });
  }
}

Future<String> _prefsDump() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return prefs.getKeys().map((k) => '$k=${prefs.get(k)}').join('\n');
}
