import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'session_signal.dart';

part 'backend_api_client.g.dart';

const _publicPaths = ['/auth/signup', '/auth/login', '/appinfo'];

/// Builds the backend `Dio` client: attaches `Authorization: Bearer <token>`
/// from secure storage on every request except signup/login/appinfo, and
/// clears the stored session on `401` (see `docs/api-reference.md`).
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
  final dio = Dio(BaseOptions(baseUrl: baseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!_publicPaths.any(options.path.contains)) {
          final token = await secureStorage.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
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
