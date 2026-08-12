import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/network/backend_api_client.dart';
import 'package:job_trigger/core/storage/secure_storage_service.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// P6-10: end-to-end coverage for the 401-mid-session flow, wiring the real
/// `dioBackendProvider` + `authNotifierProvider` together through one
/// `ProviderContainer` -- the individual-unit tests in
/// `backend_api_client_test.dart` (interceptor clears storage) and
/// `auth_notifier_test.dart` (logout flips state) each passed in isolation
/// even before the `SessionSignal` fix, which is exactly how the gap went
/// unnoticed: nothing previously exercised the two together.
class _FixedStatusAdapter implements HttpClientAdapter {
  _FixedStatusAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test(
    'a 401 on any backend request flips an already-Authenticated session to Unauthenticated',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // In the real app, `_AuthRefreshListenable` (a keepAlive provider)
      // holds a permanent `ref.listen` on `authNotifierProvider`, so it
      // never auto-disposes between reads. Replicate that here -- without
      // it, a bare `container.read` after the provider has no active
      // listener rebuilds it from scratch instead of returning live state,
      // the same auto-dispose pitfall hit repeatedly in Phase 5's polling
      // notifier tests.
      container.listen(authNotifierProvider, (_, _) {});

      final secureStorage = container.read(secureStorageProvider);
      await secureStorage.saveToken('jwt-abc');
      await container.read(authNotifierProvider.notifier).setSession(
        const User(id: 'u1', email: 'a@b.com'),
        'jwt-abc',
      );
      expect(
        container.read(authNotifierProvider).value,
        isA<Authenticated>(),
      );

      final dio = container.read(dioBackendProvider)
        ..httpClientAdapter = _FixedStatusAdapter(401);
      await expectLater(
        dio.get<void>('/api/credentials'),
        throwsA(isA<DioException>()),
      );

      // The interceptor's onUnauthorized callback -> SessionSignal ->
      // AuthNotifier's ref.listen -> logout() chain is all synchronous
      // Riverpod state propagation once the awaited request above
      // completes -- no extra pump/delay needed.
      expect(
        container.read(authNotifierProvider).value,
        isA<Unauthenticated>(),
      );
      expect(await secureStorage.readToken(), isNull);
    },
  );

  test('a 200 response does not touch an Authenticated session', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(authNotifierProvider, (_, _) {});

    await container.read(secureStorageProvider).saveToken('jwt-abc');
    await container.read(authNotifierProvider.notifier).setSession(
      const User(id: 'u1', email: 'a@b.com'),
      'jwt-abc',
    );

    final dio = container.read(dioBackendProvider)
      ..httpClientAdapter = _FixedStatusAdapter(200);
    await dio.get<void>('/api/credentials');

    expect(container.read(authNotifierProvider).value, isA<Authenticated>());
  });
}
