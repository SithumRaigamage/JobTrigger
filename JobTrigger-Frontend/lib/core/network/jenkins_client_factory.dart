import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../presentation/features/settings/active_server_notifier.dart';
import '../error/app_failure.dart';
import '../error/result.dart';

part 'jenkins_client_factory.g.dart';

/// Builds a per-server `Dio` instance with HTTP Basic Auth set once at
/// construction — Jenkins credentials aren't JWTs and don't rotate
/// mid-session (see `docs/api-reference.md#2-jenkins-api-direct-per-server-basic-auth`).
///
/// Carries an in-memory cookie jar (`CookieManager`), added after a real
/// Jenkins instance rejected every trigger POST with "No valid crumb was
/// included in the request" despite the crumb interceptor below correctly
/// fetching and attaching a crumb every time. Root cause, confirmed by
/// inspecting the actual request/response traffic: this server issues a
/// *new* `JSESSIONID` on every request, and `DefaultCrumbIssuer`'s crumb is
/// bound to the session that was active when it was issued. Without a
/// cookie jar, Dio never sends that session cookie back on the follow-up
/// POST, so Jenkins can't associate the crumb with any session and rejects
/// it — a fresh crumb via the interceptor's own retry logic doesn't help,
/// since the retry has exactly the same missing-cookie problem. In-memory
/// only (not `PersistCookieJar`): a new `Dio` instance is built per active-
/// server switch anyway, so there's nothing worth persisting across app
/// restarts, and it keeps no session data on disk.
Dio buildJenkinsDio({
  required String baseUrl,
  required String username,
  required String password,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  final basicAuth = base64Encode(utf8.encode('$username:$password'));
  dio.options.headers['Authorization'] = 'Basic $basicAuth';

  // Order matters here. `_crumbInterceptor` must run first: it triggers a
  // nested crumb-fetch request whose response is what actually populates
  // the cookie jar with the session Jenkins bound the crumb to.
  // `CookieManager` then has to run *after* it (as the next interceptor in
  // the chain, for the *same* outer request) so that when it attaches
  // cookies to the outer POST, the jar already holds that session cookie —
  // reversed, `CookieManager` would load from the jar before the crumb
  // fetch ever populates it, and the outer POST would go out with no
  // cookie at all.
  dio.interceptors.add(_crumbInterceptor(dio));
  dio.interceptors.add(CookieManager(CookieJar()));

  return dio;
}

/// Caches a Jenkins CSRF crumb for one `Dio` client's lifetime — see
/// `docs/user-stories/09-non-functional-security.md` (`NFR-SEC-06`).
/// [unavailable] means a clean 404 from the crumb issuer confirmed this
/// server has CSRF protection off, so further POSTs stop re-fetching.
class _CrumbCache {
  String? headerName;
  String? value;
  bool unavailable = false;

  bool get isSet => headerName != null && value != null;

  void clear() {
    headerName = null;
    value = null;
    unavailable = false;
  }
}

/// `GET {baseUrl}/crumbIssuer/api/json` on the same [dio] instance (a GET,
/// so it never re-enters this interceptor's POST-only logic below). A 404
/// is treated as "no crumb issuer" and cached as [_CrumbCache.unavailable];
/// any other failure is left unset so the *next* POST tries again rather
/// than permanently giving up on a transient blip.
Future<void> _fetchCrumb(Dio dio, _CrumbCache cache) async {
  try {
    final response = await dio.get<Map<String, dynamic>>(
      '/crumbIssuer/api/json',
    );
    final field = response.data?['crumbRequestField'] as String?;
    final crumb = response.data?['crumb'] as String?;
    if (field != null && crumb != null) {
      cache
        ..headerName = field
        ..value = crumb;
    }
  } on DioException catch (exception) {
    if (exception.response?.statusCode == 404) {
      cache.unavailable = true;
    }
  }
}

/// CSRF crumb interceptor (`NFR-SEC-06`): attaches a Jenkins crumb header
/// to every POST — `build`, `buildWithParameters`, `{buildNumber}/stop`,
/// and any future pipeline-mutating call — fetched lazily and cached for
/// this client's lifetime (rebuilt on server switch, same as the Basic
/// Auth header). Silently no-ops on servers without a crumb issuer.
/// Retries a 403 exactly once with a freshly-fetched crumb before giving
/// up, unless a prior clean 404 already confirmed this server has no
/// crumb issuer at all (in which case a 403 is a real auth/permission
/// failure, not a stale crumb, and retrying would only waste a round trip).
Interceptor _crumbInterceptor(Dio dio) {
  final cache = _CrumbCache();
  return InterceptorsWrapper(
    onRequest: (options, handler) async {
      if (options.method == 'POST' && !cache.unavailable) {
        if (!cache.isSet) {
          await _fetchCrumb(dio, cache);
        }
        if (cache.isSet) {
          options.headers[cache.headerName!] = cache.value;
        }
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      final alreadyRetried = error.requestOptions.extra['crumbRetried'] == true;
      if (error.response?.statusCode == 403 &&
          error.requestOptions.method == 'POST' &&
          !alreadyRetried &&
          !cache.unavailable) {
        cache.clear();
        await _fetchCrumb(dio, cache);
        if (cache.isSet) {
          final retryOptions = error.requestOptions
            ..headers[cache.headerName!] = cache.value
            ..extra['crumbRetried'] = true;
          try {
            handler.resolve(await dio.fetch<dynamic>(retryOptions));
            return;
          } on DioException catch (retryError) {
            handler.next(retryError);
            return;
          }
        }
      }
      handler.next(error);
    },
  );
}

/// Rebuilt whenever the active server changes (`docs/state-management.md`).
/// Throws if there's no active server yet — screens that depend on this
/// (via `jenkinsRepositoryProvider`, Phase 4) are expected to already gate
/// on a server being configured before reaching that point.
@riverpod
Dio jenkinsClient(Ref ref) {
  final server = ref.watch(activeServerNotifierProvider);
  if (server == null) {
    throw StateError('No active Jenkins server is configured.');
  }
  return buildJenkinsDio(
    baseUrl: server.jenkinsURL,
    username: server.username,
    password: server.secret,
  );
}

/// "Test connection" (P3-08): `GET {url}/api/json` against a throwaway
/// `Dio` instance — never the active one, so testing a new/edited server
/// doesn't disturb the active session. Returns the job count on success.
///
/// This calls Jenkins directly rather than through a `JenkinsRepository`
/// because that repository (with job-tree fetching, URL rewriting, etc.) is
/// Phase 4 scope (`tasks/phase-4-jenkins-job-tree.md`) — building it now
/// would preempt that phase's actual design. `docs/state-management.md`'s
/// mention of `jenkinsRepositoryProvider.testConnection(...)` describes the
/// eventual full picture once Phase 4 lands.
Future<Result<int, AppFailure>> testJenkinsConnection({
  required String jenkinsURL,
  required String username,
  required String password,
}) async {
  final dio = buildJenkinsDio(
    baseUrl: jenkinsURL,
    username: username,
    password: password,
  );
  try {
    final response = await dio.get<Map<String, dynamic>>('/api/json');
    final jobs = response.data?['jobs'] as List<dynamic>?;
    return Ok(jobs?.length ?? 0);
  } on DioException catch (exception) {
    return Err(AppFailure.fromDioException(exception));
  } finally {
    dio.close();
  }
}
