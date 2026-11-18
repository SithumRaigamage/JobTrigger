import 'package:dio/dio.dart';

import '../network/request_id.dart';

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
          final code? => ServerFailure(
            code,
            requestId: _requestIdOf(exception.response),
          ),
          null => const UnknownFailure(),
        };
      case DioExceptionType.badCertificate:
        // PI-03 / IMP-35: a certificate problem is a configuration issue,
        // not an unknown error — the connection help explains the fix.
        return const BadCertificateFailure();
      case DioExceptionType.cancel:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        return UnknownFailure(exception.message);
    }
  }

  /// The server can't be reached right now: a connection failure, or a
  /// gateway answering for a stopped Jenkins (502/503/504 from a reverse
  /// proxy or tunnel). Callers use it to fall back to cached data instead
  /// of showing an error.
  bool get isUnreachable => switch (this) {
    NetworkFailure() => true,
    ServerFailure(:final statusCode) =>
      statusCode == 502 || statusCode == 503 || statusCode == 504,
    _ => false,
  };

  /// P20-25: for the calls that can hit a plan limit (adding a credential,
  /// making one active): a `PLAN_LIMIT` 403 becomes a [PlanLimitFailure];
  /// everything else, including every other 403, maps exactly as
  /// [fromDioException] does.
  factory AppFailure.fromCredentialsException(DioException exception) =>
      PlanLimitFailure.tryFrom(exception) ??
      AppFailure.fromDioException(exception);

  /// Phase 21: for the student-plan calls, whose 400/409/413/415/429/503
  /// answers carry the backend's own explanation (and a `code`). Anything
  /// else maps exactly as [fromDioException] does.
  factory AppFailure.fromStudentException(DioException exception) =>
      StudentRequestFailure.tryFrom(exception) ??
      AppFailure.fromDioException(exception);

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
    BadCertificateFailure() =>
      'The server’s security certificate isn’t trusted. Check the address '
          'and your device’s date and time.',
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
    ServerFailure(:final statusCode, requestId: final id?) =>
      'Something went wrong on the server (HTTP $statusCode). '
          'Reference: $id',
    ServerFailure(:final statusCode) =>
      'Something went wrong on the server (HTTP $statusCode).',
    RateLimitFailure() =>
      "GitHub's rate limit was reached. Please wait a bit and try again.",
    UnexpectedResponseFailure() =>
      "The server sent a response the app didn't understand. Check that "
          'the server URL is correct — not a login page or proxy.',
    RejectedRequestFailure(:final serverMessage) => serverMessage,
    DispatchRejectedFailure(:final detail) =>
      detail == null
          ? _dispatchRejected
          : '$_dispatchRejected GitHub said: $detail',
    SonarQubeAccessDeniedFailure() =>
      "Your SonarQube user isn't allowed to see this. Use a token for a user "
          'who can browse the projects, then try again.',
    SonarQubeWriteDeniedFailure() =>
      "Your SonarQube user isn't allowed to make this change. The token's "
          'user needs permission to administer issues (or review security '
          'hotspots) on this project. Nothing was changed.',
    SonarQubeProjectNotFoundFailure() =>
      "SonarQube doesn't have that project any more. Go back and refresh "
          'the list.',
    SonarQubeOrganizationNotFoundFailure() =>
      "SonarCloud doesn't know that organization. Check the organization "
          'key in this credential in Settings.',
    DemoUnavailableFailure() => 'Not available in demo.',
    PlanLimitFailure(:final serverMessage) => serverMessage,
    StudentRequestFailure(:final serverMessage) => serverMessage,
    StoreFailure() =>
      "The store couldn't complete that request. Check that you're "
          'signed in to your App Store or Google Play account, then try '
          'again.',
    // Closing the store sheet is a choice, not an error: no copy.
    PurchaseCancelled() => '',
    UnknownFailure() => 'Something unexpected happened. Please try again.',
  };
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

/// PI-03 / IMP-35: the server's TLS certificate could not be verified.
/// Split out of the generic `DioExceptionType.unknown` bucket so the
/// connection-help screen can give certificate-specific advice. Expected,
/// so crash reporting ignores it like the other configuration failures.
final class BadCertificateFailure extends AppFailure {
  const BadCertificateFailure();
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
  const ServerFailure(this.statusCode, {this.requestId});

  final int statusCode;

  /// The backend's id for the failed request (P13-26), quoted in the copy
  /// so a bug report can be matched to its log lines. Null from servers
  /// that don't send one (Jenkins, GitHub).
  final String? requestId;
}

/// The `x-request-id` a response carries, if it's shaped like one.
String? _requestIdOf(Response<dynamic>? response) {
  final id = response?.headers.value('x-request-id');
  return id != null && requestIdPattern.hasMatch(id) ? id : null;
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

/// The JobTrigger backend refused the request with a 400 and its own
/// user-facing explanation ("Invalid credentials", "User already exists",
/// "Current password is incorrect"). Those messages are written for users
/// in the backend's controllers, and the central error handler never puts
/// internals in a 400 (AUD-06), so showing them is safe. Before AUD-65
/// they became "Something went wrong on the server (HTTP 400)". Backend
/// only: Jenkins' 400s are HTML pages and stay a [ServerFailure].
final class RejectedRequestFailure extends AppFailure {
  const RejectedRequestFailure(this.serverMessage);

  final String serverMessage;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([this.debugMessage]);

  final String? debugMessage;
}

/// GitHub answered a `workflow_dispatch` with 422 (`US-GH-RUN-02`): the
/// workflow has no `workflow_dispatch` trigger, or the ref or inputs were
/// rejected. The REST API can't say which ahead of time, so the copy names
/// all three and appends GitHub's own [detail] when it sent one. GitHub-only.
final class DispatchRejectedFailure extends AppFailure {
  const DispatchRejectedFailure([this.detail]);

  final String? detail;
}

const _dispatchRejected =
    "GitHub didn't accept the trigger. The workflow may not allow manual "
    'runs (it needs a workflow_dispatch trigger), or the branch or inputs '
    'are invalid.';

/// SonarCloud answered 404 to a request carrying an organization key: the
/// key is wrong or missing (`US-SQ-PROJ-01`). SonarQube-only.
final class SonarQubeOrganizationNotFoundFailure extends AppFailure {
  const SonarQubeOrganizationNotFoundFailure();
}

/// SonarQube answered 403: the token is valid, but its user may not browse
/// this (`US-SQ-PROJ-01`). Distinct from [AuthFailure] (a rejected token) and
/// from the shared [PermissionFailure], whose copy fits Jenkins, not this.
/// SonarQube-only.
final class SonarQubeAccessDeniedFailure extends AppFailure {
  const SonarQubeAccessDeniedFailure();
}

/// SonarQube answered 403 to a **change** (`US-SQ-WRITE-*`): the token is
/// valid and the user may browse, but may not modify issues or review
/// hotspots on this project. Distinct from [SonarQubeAccessDeniedFailure],
/// whose copy is about browsing. SonarQube-only.
final class SonarQubeWriteDeniedFailure extends AppFailure {
  const SonarQubeWriteDeniedFailure();
}

/// SonarQube answered 404 for a project that was in the list: it was
/// deleted or renamed since. SonarQube-only.
final class SonarQubeProjectNotFoundFailure extends AppFailure {
  const SonarQubeProjectNotFoundFailure();
}

/// E2: an action the demo does not support (everything that would write,
/// except the scripted "Trigger build"). Demo-only; no real server is involved.
final class DemoUnavailableFailure extends AppFailure {
  const DemoUnavailableFailure();
}

/// P20-21: the backend refused because the user's plan doesn't allow this
/// (`403` with `code: "PLAN_LIMIT"`). Kept apart from [PermissionFailure],
/// whose copy ("on this server") would be wrong, and produced only by
/// [PlanLimitFailure.tryFrom] on the backend client's calls that can hit a
/// limit, so every other 403 keeps meaning what it meant.
final class PlanLimitFailure extends AppFailure {
  const PlanLimitFailure(this.limit, this.serverMessage);

  /// Which limit: `maxCredentialsTotal`, `maxCredentialsPerTool`,
  /// `multiTool`, `primaryCooldown`, ... (the backend's `limit` field), so
  /// the paywall can match its headline to what the user tried.
  final String limit;

  /// The backend's own user-facing sentence.
  final String serverMessage;

  /// The failure for a `PLAN_LIMIT` response, or null for anything else.
  static PlanLimitFailure? tryFrom(DioException exception) {
    final response = exception.response;
    final data = response?.data;
    if (response?.statusCode != 403 || data is! Map) return null;
    if (data['code'] != 'PLAN_LIMIT') return null;
    final message = data['message'];
    final limit = data['limit'];
    return PlanLimitFailure(
      limit is String ? limit : 'unknown',
      message is String && message.isNotEmpty
          ? message
          : 'This needs JobTrigger Pro.',
    );
  }
}

/// P20-21: the user closed the store's purchase sheet. Not an error; the UI
/// shows nothing.
final class PurchaseCancelled extends AppFailure {
  const PurchaseCancelled();
}

/// The store or its SDK refused a purchase or restore for a reason that is
/// not the user closing the sheet: not signed in, no payment method, billing
/// unavailable on this device. Expected, so crash reporting ignores it;
/// [debugMessage] is for logs and tests, never shown.
final class StoreFailure extends AppFailure {
  const StoreFailure([this.debugMessage]);

  final String? debugMessage;
}

/// Phase 21: the backend refused a student-plan call and said why in its own
/// words ("File too large, max 5 MB", "That code has expired. Ask for a new
/// one."). Produced only by [AppFailure.fromStudentException], so no other
/// feature's 400s or 409s change meaning.
final class StudentRequestFailure extends AppFailure {
  const StudentRequestFailure(this.statusCode, this.code, this.serverMessage);

  final int statusCode;

  /// The backend's machine-readable `code`, if it sent one:
  /// `domain_not_listed`, `wrong_code`, `code_expired`, `too_many_attempts`,
  /// `email_used`, `already_used`, `under_review`, `document_used`, ...
  final String? code;

  /// The backend's user-facing sentence.
  final String serverMessage;

  /// The email's domain isn't one we verify automatically: use a document.
  bool get isDomainNotListed => code == 'domain_not_listed';

  /// The code can no longer work; the user needs a new one.
  bool get needsNewCode =>
      code == 'code_expired' ||
      code == 'too_many_attempts' ||
      code == 'no_code';

  static const _statuses = {400, 409, 413, 415, 429, 503};

  static StudentRequestFailure? tryFrom(DioException exception) {
    final response = exception.response;
    final status = response?.statusCode;
    final data = response?.data;
    if (status == null || !_statuses.contains(status) || data is! Map) {
      return null;
    }
    final message = data['message'];
    if (message is! String || message.isEmpty) return null;
    final code = data['code'];
    return StudentRequestFailure(status, code is String ? code : null, message);
  }
}
