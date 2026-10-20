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
          401 => const AuthFailure(),
          // Authenticated fine, but not allowed to do this (e.g. a Jenkins
          // user without Job/Build or Computer/Disconnect). Distinct from
          // 401 so the copy doesn't send the user off to re-enter
          // credentials that are actually correct (US-JX-12/13).
          403 => const PermissionFailure(),
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

  /// GitHub-specific: a 403 with `X-RateLimit-Remaining: 0` means the
  /// request was rejected for exceeding GitHub's rate limit, not because
  /// the credential was rejected — a real API behavior Jenkins/the backend
  /// don't have (self-hosted Jenkins has no rate limit; the backend is
  /// ours). Deliberately a separate entry point rather than a change to
  /// [fromDioException]'s generic 401/403 handling, so Jenkins/backend
  /// 403s keep meaning exactly what they already mean.
  factory AppFailure.fromGitHubException(DioException exception) {
    final response = exception.response;
    if (response?.statusCode == 403 &&
        response?.headers.value('x-ratelimit-remaining') == '0') {
      return const RateLimitFailure();
    }
    return AppFailure.fromDioException(exception);
  }

  /// Single source of consistent, user-facing error copy.
  String get message => switch (this) {
    NetworkFailure() =>
      "Can't reach the server. Check your connection and try again.",
    AuthFailure() =>
      'Your credentials were rejected. Please check them and try again.',
    PermissionFailure() =>
      "You don't have permission to do this on this server.",
    JobDisabledFailure() =>
      "This job is disabled, so it can't be built. Enable it first.",
    NotFoundFailure() => "That couldn't be found — it may have been removed.",
    // The backend throttles login and signup (AUD-05).
    ServerFailure(statusCode: 429) =>
      'Too many attempts. Please wait a few minutes and try again.',
    ServerFailure(:final statusCode) =>
      'Something went wrong on the server (HTTP $statusCode).',
    RateLimitFailure() =>
      "GitHub's rate limit was reached. Please wait a bit and try again.",
    UnexpectedResponseFailure() =>
      "The server sent a response the app didn't understand. Check that "
          'the server URL is correct — not a login page or proxy.',
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

/// Authenticated, but the server refused this action (HTTP 403, or Jenkins'
/// 400 "You need to have … permission" page for input steps).
final class PermissionFailure extends AppFailure {
  const PermissionFailure();
}

/// Jenkins refused to build a disabled job (HTTP 409 on trigger, verified).
/// The job may have been disabled since the screen loaded (US-JX-13).
final class JobDisabledFailure extends AppFailure {
  const JobDisabledFailure();
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure();
}

final class ServerFailure extends AppFailure {
  const ServerFailure(this.statusCode);

  final int statusCode;
}

/// See [AppFailure.fromGitHubException] — GitHub-only, never produced by
/// the Jenkins or backend clients.
final class RateLimitFailure extends AppFailure {
  const RateLimitFailure();
}

/// The request completed but the response couldn't be understood — an HTML
/// SSO/proxy page returned with `200`, a plugin returning an unexpected JSON
/// shape, or a malformed server URL (AUD-11). Produced only by
/// `guardRequest` (`core/error/guard.dart`). [debugMessage] is for logs and
/// tests, never shown to the user (`NFR-SEC-04`).
final class UnexpectedResponseFailure extends AppFailure {
  const UnexpectedResponseFailure([this.debugMessage]);

  final String? debugMessage;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([this.debugMessage]);

  final String? debugMessage;
}
