import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import 'app_failure.dart';
import 'result.dart';

/// Runs one repository request and guarantees a [Result] — the data-layer
/// contract from `CLAUDE.md` §5 ("never throw raw exceptions past the data
/// layer") in one place instead of a hand-written `try`/`catch` per method.
///
/// - A [DioException] goes to [recover] first (return non-null to
///   short-circuit, e.g. "404 means no test report" as `Ok(null)`), then to
///   [mapDioException] — [AppFailure.fromDioException] by default,
///   [AppFailure.fromGitHubException] for GitHub.
/// - Anything else — a `TypeError` from an HTML login page returned with
///   `200`, a `CheckedFromJsonException` from an unexpected JSON shape, a
///   `FormatException` from a malformed server URL — becomes an
///   [UnexpectedResponseFailure] (AUD-11). Before this, those escaped every
///   repository and surfaced as raw `toString()` text in the UI.
///
/// Do all parsing *and* URL rewriting inside [request] so it's covered too.
Future<Result<T, AppFailure>> guardRequest<T>(
  Future<T> Function() request, {
  AppFailure Function(DioException exception) mapDioException =
      AppFailure.fromDioException,
  Result<T, AppFailure>? Function(DioException exception)? recover,
}) async {
  try {
    return Ok(await request());
  } on DioException catch (exception) {
    final recovered = recover?.call(exception);
    if (recovered != null) return recovered;
    // Dio wraps two response-shape problems as an `unknown` DioException:
    // a body declared JSON that isn't (`FormatException`), and a body that
    // doesn't match the requested type, e.g. an HTML SSO page for a
    // `get<Map<String, dynamic>>` (`TypeError`). Neither is a transport
    // failure, so both get the unexpected-response copy.
    final cause = exception.error;
    if (cause is FormatException || cause is TypeError) {
      return Err(UnexpectedResponseFailure(exception.error.toString()));
    }
    return Err(mapDioException(exception));
  } on Object catch (error, stackTrace) {
    // Deliberately catch-all: this is the boundary the rest of the app
    // relies on never throwing. Logged so a genuine bug isn't invisible.
    developer.log(
      'Unexpected response',
      name: 'guardRequest',
      error: error,
      stackTrace: stackTrace,
    );
    return Err(UnexpectedResponseFailure(error.toString()));
  }
}
