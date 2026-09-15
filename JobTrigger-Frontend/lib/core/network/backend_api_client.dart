import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'session_signal.dart';

part 'backend_api_client.g.dart';

const _publicPaths = ['/auth/signup', '/auth/login', '/appinfo'];

/// Builds the backend `Dio` client: attaches an `x-auth-token: <token>`
/// header from secure storage on every request except signup/login/appinfo,
/// and clears the stored session on `401` (see `docs/api-reference.md`).
///
/// Uses a plain `x-auth-token` header, not `Authorization: Bearer` — verified
/// directly against `JobTrigger-Backend/middleware/auth.js`, which only
/// ever reads `req.header('x-auth-token')` with no `Bearer`-scheme handling
/// or fallback. `docs/api-reference.md` previously documented `Authorization:
/// Bearer` as the contract (aspirational, never actually matching the real
/// backend) — every authenticated request 401'd as a result, confirmed by
/// curling `/api/credentials` with a freshly-issued token directly against
/// the running backend. Fixed here rather than in the backend per CLAUDE.md
/// §7 ("don't rewrite the Node backend ... unless a task explicitly says
/// so"); the backend's actual behavior is the source of truth.
///
/// Exposed as a standalone builder — not just inlined in the provider body —
/// so the interceptor logic is unit-testable without a `ProviderContainer`.
/// [onUnauthorized] fires after the session is cleared, letting the caller
/// react (see `dioBackendProvider` wiring `SessionSignal`) without this
/// function depending on anything above `core/`.
Dio buildBackendDio({
  required String baseUrl,
  required SecureStorageService secureStorage,
  bool debugLogging = kDebugMode,
  void Function()? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      // No timeout at all previously -- any hang (network, a stalled
      // secure-storage read in the interceptor above, etc.) left a screen
      // stuck on its loading spinner forever, with no way to recover short
      // of restarting the app. `AppFailure.fromDioException` already maps
      // every timeout type to a clean, retry-able NetworkFailure.
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!_publicPaths.any(options.path.contains)) {
          final token = await secureStorage.readToken();
          if (token != null) {
            options.headers['x-auth-token'] = token;
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await secureStorage.clear();
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ),
  );

  if (debugLogging) {
    dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false),
    );
  }

  return dio;
}

@Riverpod(keepAlive: true)
Dio dioBackend(Ref ref) {
  final config = ref.watch(appConfigProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return buildBackendDio(
    baseUrl: config.backendBaseUrl,
    secureStorage: secureStorage,
    onUnauthorized: () =>
        ref.read(sessionSignalProvider.notifier).markUnauthorized(),
  );
}
