import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/network/backend_api_client.dart';
import 'package:job_trigger/core/network/request_id.dart';
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

/// A tiny backend: `/api/auth/refresh` trades `refresh-1` for a new pair
/// (when [refreshWorks]); protected paths accept only the fresh token.
class _RefreshingBackend implements HttpClientAdapter {
  _RefreshingBackend({this.refreshWorks = true, this.refreshStatus});

  final bool refreshWorks;

  /// When set, `/refresh` answers with this status (no token) instead,
  /// or with a connection error for -1.
  final int? refreshStatus;
  int refreshCalls = 0;
  final protectedTokens = <String?>[];
  final requestIds = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    ResponseBody json(Object body, int status) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
    if (options.path.endsWith('/api/auth/refresh')) {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      if (refreshStatus case final status?) {
        if (status == -1) {
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'offline',
          );
        }
        return json({'message': 'unavailable'}, status);
      }
      final sent = (options.data as Map)['refreshToken'];
      return refreshWorks && sent == 'refresh-1'
          ? json({'token': 'access-2', 'refreshToken': 'refresh-2'}, 200)
          : json({'message': 'Session expired'}, 401);
    }
    final token = options.headers['x-auth-token'] as String?;
    protectedTokens.add(token);
    requestIds.add(options.headers['x-request-id'] as String?);
    return token == 'access-2' ? json(<Object>[], 200) : json({}, 401);
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

  test(
    'sends a request id on every request, public ones too (P13-26)',
    () async {
      final adapter = _FixedStatusAdapter(200);
      final dio = buildBackendDio(
        baseUrl: 'https://example.test',
        secureStorage: secureStorage,
        debugLogging: false,
      )..httpClientAdapter = adapter;

      await dio.post<void>('/api/auth/login');
      final first = adapter.lastRequest?.headers['x-request-id'] as String?;
      await dio.post<void>('/api/auth/login');
      final second = adapter.lastRequest?.headers['x-request-id'] as String?;

      expect(first, matches(requestIdPattern));
      expect(second, matches(requestIdPattern));
      expect(first, isNot(second));
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

    expect(adapter.lastRequest?.headers.containsKey('x-auth-token'), isFalse);
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

  group('refresh on 401 (AUD-26)', () {
    late int unauthorizedCalls;

    Dio build(_RefreshingBackend backend) => buildBackendDio(
      baseUrl: 'https://example.test',
      secureStorage: secureStorage,
      debugLogging: false,
      onUnauthorized: () => unauthorizedCalls++,
    )..httpClientAdapter = backend;

    setUp(() async {
      unauthorizedCalls = 0;
      await secureStorage.saveToken('access-1');
      await secureStorage.saveRefreshToken('refresh-1');
    });

    test('renews the token and replays the request', () async {
      final backend = _RefreshingBackend();
      final response = await build(backend).get<dynamic>('/api/credentials');

      expect(response.statusCode, 200);
      expect(backend.protectedTokens, ['access-1', 'access-2']);
      // The replay is the same request, so it keeps its id (P13-26).
      expect(backend.requestIds.toSet(), hasLength(1));
      expect(await secureStorage.readToken(), 'access-2');
      expect(await secureStorage.readRefreshToken(), 'refresh-2');
      expect(unauthorizedCalls, 0);
    });

    test('concurrent 401s share one refresh', () async {
      final backend = _RefreshingBackend();
      final dio = build(backend);
      final responses = await Future.wait([
        dio.get<dynamic>('/api/credentials'),
        dio.get<dynamic>('/api/github-credentials'),
        dio.get<dynamic>('/api/sonarqube-credentials'),
      ]);
      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(backend.refreshCalls, 1);
    });

    test('a refused refresh ends the session', () async {
      final backend = _RefreshingBackend(refreshWorks: false);
      await expectLater(
        build(backend).get<void>('/api/credentials'),
        throwsA(isA<DioException>()),
      );
      expect(await secureStorage.readToken(), isNull);
      expect(await secureStorage.readRefreshToken(), isNull);
      expect(unauthorizedCalls, 1);
    });

    // AUD-47: only the server refusing the refresh token ends the session.
    for (final (label, status) in [
      ('rate limited (429)', 429),
      ('down (503)', 503),
      ('unreachable', -1),
    ]) {
      test('a refresh that is $label keeps the session', () async {
        final backend = _RefreshingBackend(refreshStatus: status);
        await expectLater(
          build(backend).get<void>('/api/credentials'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'the refresh failure, not the 401',
              status == -1 ? isNull : status,
            ),
          ),
        );
        expect(await secureStorage.readToken(), 'access-1');
        expect(await secureStorage.readRefreshToken(), 'refresh-1');
        expect(unauthorizedCalls, 0);
      });
    }

    test('without a refresh token it signs out as before', () async {
      FlutterSecureStorage.setMockInitialValues({});
      await secureStorage.saveToken('access-1');
      final backend = _RefreshingBackend();
      await expectLater(
        build(backend).get<void>('/api/credentials'),
        throwsA(isA<DioException>()),
      );
      expect(backend.refreshCalls, 0);
      expect(unauthorizedCalls, 1);
    });

    test('a login failure is never "refreshed"', () async {
      final backend = _RefreshingBackend();
      await expectLater(
        build(backend).post<void>('/api/auth/login'),
        throwsA(isA<DioException>()),
      );
      expect(backend.refreshCalls, 0);
    });
  });
}
