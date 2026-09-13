import 'package:dio/dio.dart';

/// The failure shapes every repository maps `DioException`s to before they
/// reach a notifier — see `docs/architecture.md#6-error-handling`. Screens
/// render copy from `AppFailure.message`, never by inspecting HTTP status
/// codes directly.
sealed class AppFailure {
  const AppFailure();

  /// Maps a caught `DioException` to a failure per the rules in
  /// `docs/api-reference.md#error-shapes-to-handle-explicitly`.
  factory AppFailure.fromDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        return switch (statusCode) {
          401 || 403 => const AuthFailure(),
          404 => const NotFoundFailure(),
          final code? => ServerFailure(code),
          null => const UnknownFailure(),
        };
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        return UnknownFailure(exception.message);
    }
  }

  /// Single source of consistent, user-facing error copy.
  String get message => switch (this) {
    NetworkFailure() =>
      "Can't reach the server. Check your connection and try again.",
    AuthFailure() =>
      'Your credentials were rejected. Please check them and try again.',
    NotFoundFailure() => "That couldn't be found — it may have been removed.",
    ServerFailure(:final statusCode) =>
      'Something went wrong on the server (HTTP $statusCode).',
    UnknownFailure() => 'Something unexpected happened. Please try again.',
  };
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

/// Auth failure from a 401/403. Note: this is failure scoped to whichever
/// client raised it — Jenkins auth (per-server) and backend auth (global
/// session) are never conflated, per `docs/api-reference.md`.
final class AuthFailure extends AppFailure {
  const AuthFailure();
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure();
}

final class ServerFailure extends AppFailure {
  const ServerFailure(this.statusCode);

  final int statusCode;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([this.debugMessage]);

  final String? debugMessage;
}
