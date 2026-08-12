import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/auth_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_repository.dart';

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

class _ConnectionErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('login returns an AuthSession on success', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _JsonAdapter(200, {
        'token': 'jwt-abc',
        'user': {'_id': 'u1', 'email': 'a@b.com'},
      });
    final repo = AuthRepositoryImpl(dio);

    final result = await repo.login(email: 'a@b.com', password: 'secret1');

    expect(result, isA<Ok<AuthSession, AppFailure>>());
    final session = (result as Ok<AuthSession, AppFailure>).value;
    expect(session.user.id, 'u1');
    expect(session.user.email, 'a@b.com');
    expect(session.token, 'jwt-abc');
  });

  test('login returns a failure on invalid credentials (400)', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _JsonAdapter(400, {
        'message': 'Invalid credentials',
      });
    final repo = AuthRepositoryImpl(dio);

    final result = await repo.login(email: 'a@b.com', password: 'wrong');

    expect(result, isA<Err<AuthSession, AppFailure>>());
    expect(
      (result as Err<AuthSession, AppFailure>).error,
      isA<ServerFailure>(),
    );
  });

  test('login returns NetworkFailure when the connection fails', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _ConnectionErrorAdapter();
    final repo = AuthRepositoryImpl(dio);

    final result = await repo.login(email: 'a@b.com', password: 'secret1');

    expect(result, isA<Err<AuthSession, AppFailure>>());
    expect(
      (result as Err<AuthSession, AppFailure>).error,
      isA<NetworkFailure>(),
    );
  });

  test('signup returns an AuthSession on success', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _JsonAdapter(201, {
        'token': 'jwt-new',
        'user': {'_id': 'u2', 'email': 'new@b.com'},
      });
    final repo = AuthRepositoryImpl(dio);

    final result = await repo.signup(email: 'new@b.com', password: 'secret1');

    expect(result, isA<Ok<AuthSession, AppFailure>>());
    expect((result as Ok<AuthSession, AppFailure>).value.token, 'jwt-new');
  });
}
