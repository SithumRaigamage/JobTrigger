import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/network/jenkins_client_factory.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// A fake adapter that scripts a (status, body) response per request via
/// [handler], tracking every request it saw (including a per-path/method
/// call count) so tests can assert on retry/fetch-once behavior without a
/// real Jenkins server — see `backend_api_client_test.dart`'s
/// `_FixedStatusAdapter` for the simpler single-response variant this
/// extends the idea of.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handler);

  final (int, Map<String, dynamic>) Function(
    RequestOptions options,
    int callNumberForThisPath,
  )
  handler;

  final List<RequestOptions> requests = [];
  final Map<String, int> _callCounts = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Snapshot headers into a fresh map — Dio reuses (mutates in place)
    // the same `RequestOptions` instance across a retry, so storing
    // `options` directly would make every earlier entry in [requests]
    // silently reflect the *latest* mutation too.
    requests.add(
      options.copyWith(headers: Map<String, dynamic>.from(options.headers)),
    );
    final key = '${options.method} ${options.path}';
    final callNumber = (_callCounts[key] ?? 0) + 1;
    _callCounts[key] = callNumber;
    final (status, body) = handler(options, callNumber);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWithAdapter(_ScriptedAdapter adapter) =>
    buildJenkinsDio(
        baseUrl: 'https://jenkins.test',
        username: 'user',
        password: 'pass',
      )
      ..httpClientAdapter = adapter;

/// Skips `ActiveServerNotifier`'s real network-backed rehydration — this
/// test drives active-server changes directly via `setActiveServer`.
class _NoRehydrateActiveServerNotifier extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => null;
}

const _serverA = JenkinsServer(
  id: 'a',
  serverName: 'Server A',
  jenkinsURL: 'https://a.test',
  username: 'userA',
  secret: 'passA',
);

const _serverB = JenkinsServer(
  id: 'b',
  serverName: 'Server B',
  jenkinsURL: 'https://b.test',
  username: 'userB',
  secret: 'passB',
);

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test(
    'jenkinsClientProvider rebuilds with a fresh Basic Auth header when the active server changes',
    () async {
      final container = ProviderContainer(
        overrides: [
          activeServerNotifierProvider.overrideWith(
            _NoRehydrateActiveServerNotifier.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(activeServerNotifierProvider.notifier)
          .setActiveServer(_serverA);
      final dioA = container.read(jenkinsClientProvider);
      expect(dioA.options.baseUrl, 'https://a.test');
      expect(
        dioA.options.headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('userA:passA'))}',
      );

      await container
          .read(activeServerNotifierProvider.notifier)
          .setActiveServer(_serverB);
      final dioB = container.read(jenkinsClientProvider);
      expect(dioB.options.baseUrl, 'https://b.test');
      expect(
        dioB.options.headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('userB:passB'))}',
      );

      // Not the same instance — confirms a genuine rebuild, not a stale
      // closure still pointing at Server A's Dio.
      expect(identical(dioA, dioB), isFalse);
    },
  );

  group('CSRF crumb interceptor (NFR-SEC-06)', () {
    test('attaches a crumb header fetched from the crumb issuer on a POST', () async {
      final adapter = _ScriptedAdapter((options, callNumber) {
        if (options.path == '/crumbIssuer/api/json') {
          return (200, {
            'crumbRequestField': 'Jenkins-Crumb',
            'crumb': 'abc123',
          });
        }
        return (200, <String, dynamic>{});
      });
      final dio = _dioWithAdapter(adapter);

      await dio.post<void>('/job/x/build');

      final buildRequest = adapter.requests.firstWhere(
        (r) => r.path == '/job/x/build',
      );
      expect(buildRequest.headers['Jenkins-Crumb'], 'abc123');
      expect(
        adapter.requests.where((r) => r.path == '/crumbIssuer/api/json').length,
        1,
      );
    });

    test('does not fetch a crumb for GET requests', () async {
      final adapter = _ScriptedAdapter(
        (options, callNumber) => (200, <String, dynamic>{}),
      );
      final dio = _dioWithAdapter(adapter);

      await dio.get<void>('/api/json');

      expect(
        adapter.requests.any((r) => r.path == '/crumbIssuer/api/json'),
        isFalse,
      );
    });

    test(
      'proceeds without a crumb and stops re-fetching once the crumb issuer 404s',
      () async {
        final adapter = _ScriptedAdapter((options, callNumber) {
          if (options.path == '/crumbIssuer/api/json') {
            return (404, <String, dynamic>{});
          }
          return (200, <String, dynamic>{});
        });
        final dio = _dioWithAdapter(adapter);

        await dio.post<void>('/job/x/build');
        await dio.post<void>('/job/y/build');

        expect(
          adapter.requests
              .where((r) => r.path == '/crumbIssuer/api/json')
              .length,
          1,
        );
        final secondBuild = adapter.requests.last;
        expect(secondBuild.headers.containsKey('Jenkins-Crumb'), isFalse);
      },
    );

    test(
      'retries once with a freshly-fetched crumb after a 403, then succeeds',
      () async {
        final adapter = _ScriptedAdapter((options, callNumber) {
          if (options.path == '/crumbIssuer/api/json') {
            final crumb = callNumber == 1 ? 'stale' : 'fresh';
            return (200, {'crumbRequestField': 'Jenkins-Crumb', 'crumb': crumb});
          }
          if (options.path == '/job/x/build') {
            final attached = options.headers['Jenkins-Crumb'];
            return attached == 'fresh'
                ? (200, <String, dynamic>{})
                : (403, <String, dynamic>{});
          }
          return (200, <String, dynamic>{});
        });
        final dio = _dioWithAdapter(adapter);

        await dio.post<void>('/job/x/build');

        final buildRequests = adapter.requests
            .where((r) => r.path == '/job/x/build')
            .toList();
        expect(buildRequests.length, 2);
        expect(buildRequests.first.headers['Jenkins-Crumb'], 'stale');
        expect(buildRequests.last.headers['Jenkins-Crumb'], 'fresh');
      },
    );

    test('gives up after one retry if the crumb keeps failing', () async {
      var buildCalls = 0;
      final adapter = _ScriptedAdapter((options, callNumber) {
        if (options.path == '/crumbIssuer/api/json') {
          return (200, {
            'crumbRequestField': 'Jenkins-Crumb',
            'crumb': 'c$callNumber',
          });
        }
        if (options.path == '/job/x/build') {
          buildCalls++;
          return (403, <String, dynamic>{});
        }
        return (200, <String, dynamic>{});
      });
      final dio = _dioWithAdapter(adapter);

      await expectLater(
        dio.post<void>('/job/x/build'),
        throwsA(isA<DioException>()),
      );

      // Original request + exactly one retry — no infinite loop.
      expect(buildCalls, 2);
    });
  });
}
