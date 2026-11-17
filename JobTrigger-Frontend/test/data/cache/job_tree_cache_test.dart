import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/cache/job_tree_cache.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';

void main() {
  late Directory directory;
  late JobTreeCache cache;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('jt-cache');
    cache = JobTreeCache(() async => directory);
  });
  tearDown(() => directory.deleteSync(recursive: true));

  const jobs = [
    JenkinsJob(
      name: 'team',
      url: 'https://ci/job/team/',
      jobClass: 'com.cloudbees.hudson.plugins.folder.Folder',
      jobs: [],
    ),
    JenkinsJob(
      name: 'api',
      url: 'https://ci/job/api/',
      color: 'red',
      buildable: true,
      lastBuild: JenkinsBuild(
        number: 42,
        url: 'https://ci/job/api/42/',
        result: 'FAILURE',
        timestamp: 1000,
      ),
    ),
  ];

  test('round-trips a listing with its save time (US-JX-20)', () async {
    final savedAt = DateTime.utc(2026, 9, 30, 14, 32);
    await cache.write('s1', '', jobs, now: savedAt);

    final cached = await cache.read('s1', '');

    expect(cached!.savedAt, savedAt);
    expect(cached.jobs.first.isFolder, isTrue);
    expect(cached.jobs.last.color, 'red');
    expect(cached.jobs.last.lastBuild?.number, 42);
    expect(cached.jobs.last.lastBuild?.result, 'FAILURE');
  });

  test('servers and folders are separate entries', () async {
    await cache.write('s1', '', jobs);
    expect(await cache.read('s2', ''), isNull);
    expect(await cache.read('s1', 'https://ci/job/team/'), isNull);
  });

  test('a corrupt entry reads as no cache', () async {
    await cache.write('s1', '', jobs);
    for (final file in directory.listSync(recursive: true).whereType<File>()) {
      file.writeAsStringSync('{not json');
    }
    expect(await cache.read('s1', ''), isNull);
  });

  test('clearServer and clearAll delete what they should', () async {
    await cache.write('s1', '', jobs);
    await cache.write('s2', '', jobs);

    await cache.clearServer('s1');
    expect(await cache.read('s1', ''), isNull);
    expect(await cache.read('s2', ''), isNotNull);

    await cache.clearAll();
    expect(await cache.read('s2', ''), isNull);
  });
}
