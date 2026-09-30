import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/cache/build_watch_store.dart';
import 'package:job_trigger/domain/jenkins/build_watch.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const watch = BuildWatch(
    serverId: 's1',
    jobUrl: 'https://ci/job/api/',
    jobLabel: 'api',
    buildNumber: 7,
  );

  test('starts empty', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await BuildWatchStore().load(), isEmpty);
  });

  test('round-trips watches', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BuildWatchStore();
    await store.save([watch]);
    final loaded = await store.load();
    expect(loaded.single.key, watch.key);
    expect(loaded.single.buildNumber, 7);
    expect(loaded.single.jobLabel, 'api');
  });

  test('a corrupt entry loads as empty instead of throwing', () async {
    SharedPreferences.setMockInitialValues({'build_watches': '{not json'});
    expect(await BuildWatchStore().load(), isEmpty);
  });
}
