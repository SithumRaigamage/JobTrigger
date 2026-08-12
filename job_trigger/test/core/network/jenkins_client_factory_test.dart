import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/network/jenkins_client_factory.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

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
}
