import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/datasources/jenkins_client_factory.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/settings/test_connection_notifier.dart';

/// US-CRED-06: "Test connection" against a real HTTP server on loopback.
/// The server checks the Basic Auth header like Jenkins does.
Future<HttpServer> _jenkins({int jobs = 3}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final good = 'Basic ${base64Encode(utf8.encode('sam:right'))}';
  server.listen((request) {
    final ok = request.headers.value('authorization') == good;
    request.response
      ..statusCode = ok ? 200 : 401
      ..headers.contentType = ContentType.json
      ..write(
        ok ? jsonEncode({'jobs': List.filled(jobs, <String, Object>{})}) : '{}',
      );
    request.response.close();
  });
  return server;
}

String _url(HttpServer s) => 'http://${s.address.address}:${s.port}';

class _Active extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 'prod',
    serverName: 'Production',
    jenkinsURL: 'https://prod.example.com',
    username: 'admin',
    secret: 'keep',
  );
}

void main() {
  test('a good login reports the job count', () async {
    final server = await _jenkins(jobs: 17);
    addTearDown(() => server.close(force: true));

    final result = await testJenkinsConnection(
      jenkinsURL: _url(server),
      username: 'sam',
      password: 'right',
    );

    expect(result, isA<Ok<int, AppFailure>>());
    expect((result as Ok<int, AppFailure>).value, 17);
  });

  test('rejected credentials are an AuthFailure, not a network one', () async {
    final server = await _jenkins();
    addTearDown(() => server.close(force: true));

    final result = await testJenkinsConnection(
      jenkinsURL: _url(server),
      username: 'sam',
      password: 'wrong',
    );

    final failure = (result as Err<int, AppFailure>).error;
    expect(failure, isA<AuthFailure>());
    expect(failure.message, isNot(const NetworkFailure().message));
  });

  test('an unreachable host is a NetworkFailure', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final url = _url(server);
    await server.close(force: true);

    final result = await testJenkinsConnection(
      jenkinsURL: url,
      username: 'sam',
      password: 'right',
    );

    expect((result as Err<int, AppFailure>).error, isA<NetworkFailure>());
  });

  test(
    'testing a candidate leaves the active server and client alone',
    () async {
      final server = await _jenkins(jobs: 2);
      addTearDown(() => server.close(force: true));
      final container = ProviderContainer(
        overrides: [activeServerNotifierProvider.overrideWith(_Active.new)],
      );
      addTearDown(container.dispose);
      container.listen(jenkinsClientProvider, (_, _) {});
      final before = container.read(jenkinsClientProvider);

      final sub = container.listen(testConnectionNotifierProvider, (_, _) {});
      await container
          .read(testConnectionNotifierProvider.notifier)
          .test(jenkinsURL: _url(server), username: 'sam', password: 'right');

      expect(sub.read().value, 2);
      expect(container.read(activeServerNotifierProvider)?.id, 'prod');
      expect(identical(container.read(jenkinsClientProvider), before), isTrue);
      expect(before.options.baseUrl, 'https://prod.example.com');
    },
  );
}
