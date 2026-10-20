import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/storage/secure_storage_service.dart';
import 'package:job_trigger/data/repositories/auth_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_repository.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements AuthRepository {
  _Repo(this.result);

  final Result<void, AppFailure> result;
  int calls = 0;

  @override
  Future<Result<void, AppFailure>> logoutEverywhere() async {
    calls++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Adapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> signedIn(_Repo repo) async {
    final c = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    await c.read(authNotifierProvider.future);
    await c
        .read(authNotifierProvider.notifier)
        .setSession(
          const User(id: 'u1', email: 'a@b.com'),
          'access',
          refreshToken: 'refresh',
        );
    return c;
  }

  final storage = SecureStorageService(const FlutterSecureStorage());

  test(
    'a session keeps its refresh token in secure storage (AUD-26)',
    () async {
      await signedIn(_Repo(const Ok(null)));
      expect(await storage.readRefreshToken(), 'refresh');
    },
  );

  test('logging out everywhere revokes, then signs out here', () async {
    final repo = _Repo(const Ok(null));
    final c = await signedIn(repo);

    final failure = await c
        .read(authNotifierProvider.notifier)
        .logoutEverywhere();

    expect(failure, isNull);
    expect(repo.calls, 1);
    expect(c.read(authNotifierProvider).value, isA<Unauthenticated>());
    expect(await storage.readToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
  });

  test('if the server can\'t be told, the user stays signed in', () async {
    final c = await signedIn(_Repo(const Err(NetworkFailure())));

    final failure = await c
        .read(authNotifierProvider.notifier)
        .logoutEverywhere();

    expect(failure, isA<NetworkFailure>());
    expect(c.read(authNotifierProvider).value, isA<Authenticated>());
  });

  test('the repository POSTs /api/auth/logout-all', () async {
    final adapter = _Adapter();
    final repo = AuthRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'https://backend.test'))
        ..httpClientAdapter = adapter,
    );
    final result = await repo.logoutEverywhere();
    expect(result, isA<Ok<void, AppFailure>>());
    expect(adapter.last?.method, 'POST');
    expect(adapter.last?.path, '/api/auth/logout-all');
  });
}
