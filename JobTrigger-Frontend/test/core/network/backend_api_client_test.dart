import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/network/backend_api_client.dart';
import 'package:job_trigger/core/storage/secure_storage_service.dart';

/// A fake adapter that always responds with a fixed status code, so tests
/// don't need a real backend — see `docs/api-reference.md`'s interceptor
/// contract.
class _FixedStatusAdapter implements HttpClientAdapter {
  _FixedStatusAdapter(this.statusCode);

  final int statusCode;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late SecureStorageService secureStorage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    secureStorage = SecureStorageService(const FlutterSecureStorage());
  });

  test(
    'attaches x-auth-token from secure storage on protected paths',
    () async {
      await secureStorage.saveToken('token-123');
      final adapter = _FixedStatusAdapter(200);
      final dio = buildBackendDio(
        baseUrl: 'https://example.test',
        secureStorage: secureStorage,
        debugLogging: false,
      )..httpClientAdapter = adapter;

      await dio.get<void>('/api/credentials');

      expect(adapter.lastRequest?.headers['x-auth-token'], 'token-123');
    },
  );

  test('does not attach x-auth-token on public paths', () async {
    await secureStorage.saveToken('token-123');
    final adapter = _FixedStatusAdapter(200);
    final dio = buildBackendDio(
      baseUrl: 'https://example.test',
      secureStorage: secureStorage,
      debugLogging: false,
    )..httpClientAdapter = adapter;

    await dio.post<void>('/api/auth/login');

    expect(
      adapter.lastRequest?.headers.containsKey('x-auth-token'),
      isFalse,
    );
  });

  test('a 401 response clears the stored session', () async {
    await secureStorage.saveToken('token-123');
    final dio = buildBackendDio(
      baseUrl: 'https://example.test',
      secureStorage: secureStorage,
      debugLogging: false,
    )..httpClientAdapter = _FixedStatusAdapter(401);

    await expectLater(
      dio.get<void>('/api/credentials'),
      throwsA(isA<DioException>()),
    );

    expect(await secureStorage.readToken(), isNull);
  });

  test('a 200 response leaves the stored session untouched', () async {
    await secureStorage.saveToken('token-123');
    final dio = buildBackendDio(
      baseUrl: 'https://example.test',
      secureStorage: secureStorage,
      debugLogging: false,
    )..httpClientAdapter = _FixedStatusAdapter(200);

    await dio.get<void>('/api/credentials');

    expect(await secureStorage.readToken(), 'token-123');
  });
}
