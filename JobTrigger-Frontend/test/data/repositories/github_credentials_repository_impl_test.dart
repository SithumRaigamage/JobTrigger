import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/github_credentials_repository.dart';

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
  'token': 'ghp_faketoken',
  'defaultOwner': 'octocat',
  'isDefault': isDefault,
};

void main() {
  test('fetchAll maps the JSON array to GitHubCredential entities', () async {
    final adapter = _JsonAdapter(200, [
      _credentialJson(id: 'c1'),
      _credentialJson(id: 'c2'),
    ]);
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final repo = GitHubCredentialsRepositoryImpl(dio);

    final result = await repo.fetchAll();

    expect(result, isA<Ok<List<GitHubCredential>, AppFailure>>());
    final credentials =
        (result as Ok<List<GitHubCredential>, AppFailure>).value;
    expect(credentials, hasLength(2));
    expect(credentials.first.id, 'c1');
    expect(credentials.first.secret, 'ghp_faketoken'); // token -> secret rename
    expect(credentials.first.defaultOwner, 'octocat');
  });

  test('add posts label/token/defaultOwner/isDefault', () async {
    final adapter = _JsonAdapter(201, _credentialJson());
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final repo = GitHubCredentialsRepositoryImpl(dio);

    final result = await repo.add(
      label: 'Personal',
      secret: 'ghp_faketoken',
      defaultOwner: 'octocat',
      isDefault: false,
    );

    expect(result, isA<Ok<GitHubCredential, AppFailure>>());
    final body = adapter.lastRequest?.data as Map<String, dynamic>?;
    expect(body?['token'], 'ghp_faketoken'); // secret -> token on the wire
    expect(body?['label'], 'Personal');
    expect(body?['defaultOwner'], 'octocat');
  });

  test(
    'delete succeeds on a non-throwing 2xx regardless of body shape',
    () async {
      final adapter = _JsonAdapter(200, {'message': 'Credential removed'});
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter;
      final repo = GitHubCredentialsRepositoryImpl(dio);

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
    final repo = GitHubCredentialsRepositoryImpl(dio);

    final result = await repo.switchActive('c1');

    expect(result, isA<Ok<GitHubCredential, AppFailure>>());
    expect(
      (result as Ok<GitHubCredential, AppFailure>).value.isDefault,
      isTrue,
    );
  });

  test('fetchAll returns a failure on a non-2xx response', () async {
    final adapter = _JsonAdapter(500, {'message': 'Server error'});
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter;
    final GitHubCredentialsRepository repo = GitHubCredentialsRepositoryImpl(
      dio,
    );

    final result = await repo.fetchAll();

    expect(result, isA<Err<List<GitHubCredential>, AppFailure>>());
    expect(
      (result as Err<List<GitHubCredential>, AppFailure>).error,
      isA<ServerFailure>(),
    );
  });
}
