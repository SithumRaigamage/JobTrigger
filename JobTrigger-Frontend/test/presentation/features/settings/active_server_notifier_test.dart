import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// In-memory fake so fallback logic can be tested without mocking Dio.
class _FakeCredentialsRepository implements CredentialsRepository {
  _FakeCredentialsRepository(this._servers);

  final List<JenkinsServer> _servers;

  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      Ok(List.of(_servers));

  @override
  Future<Result<void, AppFailure>> delete(String id) async {
    _servers.removeWhere((server) => server.id == id);
    return const Ok(null);
  }

  @override
  Future<Result<JenkinsServer, AppFailure>> add({
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) => throw UnimplementedError();

  @override
  Future<Result<JenkinsServer, AppFailure>> update(
    String id, {
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) => throw UnimplementedError();

  @override
  Future<Result<JenkinsServer, AppFailure>> switchActive(String id) =>
      throw UnimplementedError();
}

JenkinsServer _server(String id, {bool isDefault = false}) => JenkinsServer(
  id: id,
  serverName: 'Server $id',
  jenkinsURL: 'https://$id.test',
  username: 'user',
  secret: 'pass',
  isDefault: isDefault,
);

ProviderContainer _containerWith(List<JenkinsServer> servers) {
  final repo = _FakeCredentialsRepository(servers);
  return ProviderContainer(
    overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
  );
}

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test(
    'deleting the active server falls back to the remaining isDefault server',
    () async {
      final serverA = _server('a');
      final serverB = _server('b', isDefault: true);
      final container = _containerWith([serverA, serverB]);
      addTearDown(container.dispose);

      final notifier = container.read(activeServerNotifierProvider.notifier);
      await notifier.setActiveServer(serverA);

      final result = await notifier.deleteServer(serverA);

      expect(result, isA<Ok<void, AppFailure>>());
      expect(container.read(activeServerNotifierProvider)?.id, 'b');
    },
  );

  test(
    'deleting the active server falls back to the first remaining server when none is default',
    () async {
      final serverA = _server('a');
      final serverB = _server('b');
      final container = _containerWith([serverA, serverB]);
      addTearDown(container.dispose);

      final notifier = container.read(activeServerNotifierProvider.notifier);
      await notifier.setActiveServer(serverA);

      await notifier.deleteServer(serverA);

      expect(container.read(activeServerNotifierProvider)?.id, 'b');
    },
  );

  test('deleting the only server clears the active server', () async {
    final serverA = _server('a');
    final container = _containerWith([serverA]);
    addTearDown(container.dispose);

    final notifier = container.read(activeServerNotifierProvider.notifier);
    await notifier.setActiveServer(serverA);

    await notifier.deleteServer(serverA);

    expect(container.read(activeServerNotifierProvider), isNull);
  });

  test(
    'deleting a non-active server leaves the active server untouched',
    () async {
      final serverA = _server('a');
      final serverB = _server('b');
      final container = _containerWith([serverA, serverB]);
      addTearDown(container.dispose);

      final notifier = container.read(activeServerNotifierProvider.notifier);
      await notifier.setActiveServer(serverA);

      await notifier.deleteServer(serverB);

      expect(container.read(activeServerNotifierProvider)?.id, 'a');
    },
  );
}
