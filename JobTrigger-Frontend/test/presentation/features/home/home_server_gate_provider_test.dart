import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/home/home_server_gate_provider.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _server = JenkinsServer(
  id: 's1',
  serverName: 'Server',
  jenkinsURL: 'https://jenkins.test',
  username: 'user',
  secret: 'secret',
);

class _Credentials extends CredentialsNotifier {
  _Credentials(this._load);

  final Future<List<JenkinsServer>> Function() _load;

  @override
  Future<List<JenkinsServer>> build() => _load();
}

ProviderContainer _container(Future<List<JenkinsServer>> Function() load) {
  final container = ProviderContainer(
    // A failed load must stay failed, not be retried behind the test.
    retry: (_, _) => null,
    overrides: [
      credentialsNotifierProvider.overrideWith(() => _Credentials(load)),
    ],
  );
  addTearDown(container.dispose);
  // Home watches both; keep them alive like the screen does.
  container.listen(homeServerGateProvider, (_, _) {});
  return container;
}

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test('is loading while the saved servers are still being fetched', () {
    final pending = Completer<List<JenkinsServer>>();
    final container = _container(() => pending.future);

    expect(container.read(homeServerGateProvider), isA<HomeServerLoading>());
  });

  test(
    'stays loading, not "none", while the active server is chosen',
    () async {
      final container = _container(() async => [_server]);

      await container.read(credentialsNotifierProvider.future);

      expect(container.read(homeServerGateProvider), isA<HomeServerLoading>());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(activeServerNotifierProvider)?.id, 's1');
    },
  );

  test('reports none only once the list has loaded empty', () async {
    final container = _container(() async => const []);

    await container.read(credentialsNotifierProvider.future);

    expect(container.read(homeServerGateProvider), isA<HomeServerNone>());
  });

  test('reports a failed load with its error', () async {
    final container = _container(() async => throw const NetworkFailure());

    await expectLater(
      container.read(credentialsNotifierProvider.future),
      throwsA(isA<AppFailure>()),
    );

    final gate = container.read(homeServerGateProvider);
    expect(gate, isA<HomeServerFailed>());
    expect((gate as HomeServerFailed).error, isA<NetworkFailure>());
  });
}
