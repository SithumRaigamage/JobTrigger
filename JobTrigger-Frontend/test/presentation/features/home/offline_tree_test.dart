import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/cache/job_tree_cache.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/home/folder_contents_notifier.dart';
import 'package:job_trigger/presentation/features/home/home_screen.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_jenkins_repository.dart';

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 's1',
    serverName: 's1',
    jenkinsURL: 'https://ci',
    username: 'u',
    secret: 's',
  );
}

class _Repo extends FakeJenkinsRepository {
  bool online = true;

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(
    String? folderUrl,
  ) async => online
      ? const Ok([JenkinsJob(name: 'api', url: 'https://ci/job/api/')])
      : const Err(NetworkFailure());
}

void main() {
  late Directory directory;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    directory = Directory.systemTemp.createTempSync('jt-offline');
  });
  tearDown(() => directory.deleteSync(recursive: true));

  ProviderContainer container(_Repo repo) {
    final c = ProviderContainer(
      overrides: [
        jenkinsRepositoryProvider.overrideWithValue(repo),
        activeServerNotifierProvider.overrideWith(_Server.new),
        jobTreeCacheProvider.overrideWithValue(
          JobTreeCache(() async => directory),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.listen(folderContentsNotifierProvider(rootFolderKey), (_, _) {});
    return c;
  }

  test(
    'offline, the last saved listing is served and flagged (US-JX-20)',
    () async {
      final repo = _Repo();
      final c = container(repo);
      await c.read(folderContentsNotifierProvider(rootFolderKey).future);
      // Let the background cache write finish.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      repo.online = false;
      c.invalidate(folderContentsNotifierProvider(rootFolderKey));
      final jobs = await c.read(
        folderContentsNotifierProvider(rootFolderKey).future,
      );

      expect(jobs.single.name, 'api');
      expect(c.read(offlineSnapshotNotifierProvider), isNotNull);

      repo.online = true;
      c.invalidate(folderContentsNotifierProvider(rootFolderKey));
      await c.read(folderContentsNotifierProvider(rootFolderKey).future);
      expect(c.read(offlineSnapshotNotifierProvider), isNull);
    },
  );

  test('offline with nothing cached is still an error, not empty', () async {
    final c = container(_Repo()..online = false);
    // Not `.future`: Riverpod retries a failed provider with backoff, so
    // the future would wait out the retries. The first failure is enough.
    for (var i = 0; i < 20; i++) {
      if (c.read(folderContentsNotifierProvider(rootFolderKey)).hasError) break;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final state = c.read(folderContentsNotifierProvider(rootFolderKey));
    expect(state.error, isA<NetworkFailure>());
    expect(state.hasValue, isFalse);
  });

  testWidgets('Home shows the offline banner', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jenkinsRepositoryProvider.overrideWithValue(_Repo()..online = false),
          activeServerNotifierProvider.overrideWith(_Server.new),
          // In memory: real file I/O doesn't progress under the widget
          // tester's fake clock (the file cache has its own tests).
          jobTreeCacheProvider.overrideWithValue(_MemoryCache()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Offline — showing data from 14:32'),
      findsOneWidget,
    );
    expect(find.text('api'), findsOneWidget);
  });
}

class _MemoryCache extends JobTreeCache {
  _MemoryCache() : super(() => throw UnimplementedError());

  @override
  Future<CachedListing?> read(String serverId, String folderKey) async => (
    jobs: const [JenkinsJob(name: 'api', url: 'https://ci/job/api/')],
    savedAt: DateTime(2026, 9, 30, 14, 32),
  );

  @override
  Future<void> write(
    String serverId,
    String folderKey,
    List<JenkinsJob> jobs, {
    DateTime? now,
  }) async {}
}
