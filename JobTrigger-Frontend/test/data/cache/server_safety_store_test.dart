import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/cache/server_safety_store.dart';
import 'package:job_trigger/domain/safety/server_safety.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('starts empty', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await ServerSafetyStore().load(), const ServerSafety());
  });

  test('round-trips read-only and protected flags', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ServerSafetyStore();
    final safety = const ServerSafety()
        .withReadOnly(SafetyTool.githubActions, 'g1', true)
        .withProtected(SafetyTool.jenkins, 'deploy', true);

    await store.save(safety);

    final loaded = await store.load();
    expect(loaded, safety);
    expect(loaded.isReadOnly(SafetyTool.githubActions, 'g1'), isTrue);
    expect(loaded.isProtected(SafetyTool.jenkins, 'deploy'), isTrue);
  });

  test('corrupt JSON loads as empty instead of throwing', () async {
    SharedPreferences.setMockInitialValues({
      ServerSafetyStore.key: '{not json',
    });
    expect(await ServerSafetyStore().load(), const ServerSafety());
  });
}
