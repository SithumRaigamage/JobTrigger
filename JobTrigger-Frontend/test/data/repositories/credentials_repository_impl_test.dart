import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.statusCode, this.body);

  final int statusCode;
  final dynamic body;

  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _credentialJson({
  String id = 'c1',
  bool isDefault = false,
}) => {
  '_id': id,
  'serverName': 'My Jenkins',
  'jenkinsURL': 'https://jenkins.test',
  'username': 'user',
  'password': 'pass',
  'paramToken': 'tok',
  'isDefault': isDefault,
};

void main() {
  test('fetchAll maps the JSON array to JenkinsServer entities', () async {
    final adapter = _JsonAdapter(200, [
      _credentialJson(id: 'c1'),
      _credentialJson(id: 'c2'),
    ]);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final repo = CredentialsRepositoryImpl(dio);

    final result = await repo.fetchAll();

    expect(result, isA<Ok<List<JenkinsServer>, AppFailure>>());
    final servers = (result as Ok<List<JenkinsServer>, AppFailure>).value;
    expect(servers, hasLength(2));
    expect(servers.first.id, 'c1');
    expect(servers.first.secret, 'pass'); // password -> secret rename
  });

  test(
    'add posts serverName/jenkinsURL/username/password/paramToken/isDefault',
    () async {
      final adapter = _JsonAdapter(201, _credentialJson());
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final repo = CredentialsRepositoryImpl(dio);

      final result = await repo.add(
        serverName: 'My Jenkins',
        jenkinsURL: 'https://jenkins.test',
        username: 'user',
        secret: 'pass',
        paramToken: 'tok',
        isDefault: false,
      );

      expect(result, isA<Ok<JenkinsServer, AppFailure>>());
      final body = adapter.lastRequest?.data as Map<String, dynamic>?;
      expect(body?['password'], 'pass'); // secret -> password on the wire
      expect(body?['serverName'], 'My Jenkins');
    },
  );

  test(
    'delete succeeds on a non-throwing 2xx regardless of body shape',
    () async {
      // Real backend returns { message: 'Credential removed' }, not
      // { success } as docs/api-reference.md states — delete() must not
      // depend on a `success` field.
      final adapter = _JsonAdapter(200, {'message': 'Credential removed'});
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final repo = CredentialsRepositoryImpl(dio);

      final result = await repo.delete('c1');

      expect(result, isA<Ok<void, AppFailure>>());
    },
  );

  test('switchActive returns the flipped credential', () async {
    final adapter = _JsonAdapter(
      200,
      _credentialJson(id: 'c1', isDefault: true),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final repo = CredentialsRepositoryImpl(dio);

    final result = await repo.switchActive('c1');

    expect(result, isA<Ok<JenkinsServer, AppFailure>>());
    expect((result as Ok<JenkinsServer, AppFailure>).value.isDefault, isTrue);
  });

  test('fetchAll returns a failure on a non-2xx response', () async {
    final adapter = _JsonAdapter(500, {'message': 'Server error'});
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final CredentialsRepository repo = CredentialsRepositoryImpl(dio);

    final result = await repo.fetchAll();

    expect(result, isA<Err<List<JenkinsServer>, AppFailure>>());
    expect(
      (result as Err<List<JenkinsServer>, AppFailure>).error,
      isA<ServerFailure>(),
    );
  });
}
