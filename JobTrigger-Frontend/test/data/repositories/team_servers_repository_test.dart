import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/storage/secure_storage_service.dart';
import 'package:job_trigger/data/credentials/credential_secrets.dart';
import 'package:job_trigger/data/models/subscription/subscription_dto.dart';
import 'package:job_trigger/data/repositories/team_servers_repository_impl.dart';
import 'package:job_trigger/domain/subscription/subscription_status.dart';
import 'package:job_trigger/domain/team/team_server.dart';

// US-SUB-11 AC16 (subscription source) and AC17 (team servers, data side).

class _Backend implements HttpClientAdapter {
  _Backend(this.routes);
  final Map<String, (int, Object?)> routes;
  final requests = <String>[];

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

const _row = {
  'id': 'c1',
  'tool': 'jenkins',
  'serverName': 'prod-ci',
  'jenkinsURL': 'https://ci.example.com',
  'username': 'svc',
  'secretMask': '••••word',
  'hasParamToken': false,
  'needsReentry': false,
  'sharedBy': 'owner@example.com',
  'updatedAt': '2026-11-20T10:00:00.000Z',
};

(TeamServersRepositoryImpl, _Backend) _make(
  Map<String, (int, Object?)> routes,
) {
  final backend = _Backend(routes);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = backend;
  final storage = SecureStorageService(const FlutterSecureStorage());
  return (
    TeamServersRepositoryImpl(dio, CredentialSecrets(dio, storage)),
    backend,
  );
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('lists shared servers with the secret from the team endpoint', () async {
    final (repo, backend) = _make({
      'GET /api/team/servers': (200, [_row]),
      'GET /api/team/servers/jenkins/c1/secret': (
        200,
        {
          'password': 'p4ssword',
          'paramToken': null,
          'needsReentry': false,
          'version': '2026-11-20T10:00:00.000Z',
        },
      ),
    });

    final servers =
        (await repo.fetchShared() as Ok<List<TeamServer>, AppFailure>).value;

    expect(servers, hasLength(1));
    final server = servers.single.server;
    expect(server.id, 'team:c1');
    expect(TeamServer.isTeamId(server.id), isTrue);
    expect(server.serverName, 'prod-ci');
    expect(server.secret, 'p4ssword');
    expect(servers.single.sharedBy, 'owner@example.com');
    expect(backend.requests, [
      'GET /api/team/servers',
      'GET /api/team/servers/jenkins/c1/secret',
    ]);

    // Cached by version: a second load doesn't ask for the secret again.
    await repo.fetchShared();
    expect(backend.requests.where((r) => r.endsWith('/secret')), hasLength(1));
  });

  test('a backend with teams off (404) means no team servers', () async {
    final (repo, _) = _make({});
    expect(await repo.fetchShared(), isA<Ok<List<TeamServer>, AppFailure>>());
    expect(
      (await repo.fetchShared() as Ok<List<TeamServer>, AppFailure>).value,
      isEmpty,
    );
  });

  test('an unreadable shared secret is listed but not fetched', () async {
    final (repo, backend) = _make({
      'GET /api/team/servers': (
        200,
        [
          {..._row, 'needsReentry': true},
        ],
      ),
    });
    final server =
        (await repo.fetchShared() as Ok<List<TeamServer>, AppFailure>)
            .value
            .single
            .server;
    expect(server.secret, isNull);
    expect(server.needsReentry, isTrue);
    expect(backend.requests, ['GET /api/team/servers']);
  });

  test('a 5xx is a failure, not an empty list', () async {
    final (repo, _) = _make({
      'GET /api/team/servers': (500, {'message': 'Server error'}),
    });
    expect(await repo.fetchShared(), isA<Err<List<TeamServer>, AppFailure>>());
  });

  group('subscription team (AC16)', () {
    Map<String, dynamic> body(Map<String, dynamic> extra) => {
      'plan': 'pro',
      'billingEnabled': true,
      'status': 'active',
      'limits': <String, dynamic>{},
      'features': <String, dynamic>{},
      ...extra,
    };

    test('reads source team and the membership', () {
      final status = SubscriptionDto.fromJson(
        body({
          'source': 'team',
          'team': {
            'id': 't1',
            'name': 'Platform',
            'role': 'member',
            'active': true,
          },
        }),
      ).toDomain().status;
      expect(status.isTeam, isTrue);
      expect(status.source, SubscriptionSource.team);
      expect(status.team?.name, 'Platform');
      expect(status.team?.isOwner, isFalse);
      expect(status.team?.active, isTrue);
    });

    test('no team field is no membership', () {
      final status = SubscriptionDto.fromJson(
        body({'source': 'web'}),
      ).toDomain().status;
      expect(status.team, isNull);
      expect(status.isTeam, isFalse);
    });
  });
}
