import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/sonarqube_credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/credential/sonarqube_credentials_repository.dart';

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
  'label': 'Personal',
  'baseUrl': 'https://sonarcloud.io',
  'token': 'squ_faketoken',
  'defaultOrganization': 'octocat-org',
  'isDefault': isDefault,
};

void main() {
  test('fetchAll maps the JSON array to SonarQubeCredential entities', () async {
    final adapter = _JsonAdapter(200, [
      _credentialJson(id: 'c1'),
      _credentialJson(id: 'c2'),
    ]);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final repo = SonarQubeCredentialsRepositoryImpl(dio);

    final result = await repo.fetchAll();

    expect(result, isA<Ok<List<SonarQubeCredential>, AppFailure>>());
    final credentials =
        (result as Ok<List<SonarQubeCredential>, AppFailure>).value;
    expect(credentials, hasLength(2));
    expect(credentials.first.id, 'c1');
    expect(credentials.first.secret, 'squ_faketoken'); // token -> secret rename
    expect(credentials.first.baseUrl, 'https://sonarcloud.io');
    expect(credentials.first.defaultOrganization, 'octocat-org');
  });

  test('add posts label/baseUrl/token/defaultOrganization/isDefault', () async {
    final adapter = _JsonAdapter(201, _credentialJson());
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final repo = SonarQubeCredentialsRepositoryImpl(dio);

    final result = await repo.add(
      label: 'Personal',
      baseUrl: 'https://sonarcloud.io',
      secret: 'squ_faketoken',
      defaultOrganization: 'octocat-org',
      isDefault: false,
    );

    expect(result, isA<Ok<SonarQubeCredential, AppFailure>>());
    final body = adapter.lastRequest?.data as Map<String, dynamic>?;
    expect(body?['token'], 'squ_faketoken'); // secret -> token on the wire
    expect(body?['label'], 'Personal');
    expect(body?['baseUrl'], 'https://sonarcloud.io');
    expect(body?['defaultOrganization'], 'octocat-org');
  });

  test(
    'delete succeeds on a non-throwing 2xx regardless of body shape',
    () async {
      final adapter = _JsonAdapter(200, {'message': 'Credential removed'});
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final repo = SonarQubeCredentialsRepositoryImpl(dio);

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
    final repo = SonarQubeCredentialsRepositoryImpl(dio);

    final result = await repo.switchActive('c1');

    expect(result, isA<Ok<SonarQubeCredential, AppFailure>>());
    expect(
      (result as Ok<SonarQubeCredential, AppFailure>).value.isDefault,
      isTrue,
    );
  });

  test('fetchAll returns a failure on a non-2xx response', () async {
    final adapter = _JsonAdapter(500, {'message': 'Server error'});
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final SonarQubeCredentialsRepository repo =
        SonarQubeCredentialsRepositoryImpl(dio);

    final result = await repo.fetchAll();

    expect(result, isA<Err<List<SonarQubeCredential>, AppFailure>>());
    expect(
      (result as Err<List<SonarQubeCredential>, AppFailure>).error,
      isA<ServerFailure>(),
    );
  });
}
