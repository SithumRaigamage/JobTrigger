import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/presentation/features/build_log/build_log_notifier.dart';
import 'package:job_trigger/core/platform/temp_files.dart';
import 'package:job_trigger/presentation/features/build_log/console_notifiers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_jenkins_repository.dart';

const _url = 'https://ci.test/job/a/3/';

class _Repo extends FakeJenkinsRepository {
  _Repo(this.text);

  final String text;
  List<String>? timestamps = const [];
  int? timestampStart;
  String? downloadedTo;

  @override
  Future<Result<int, AppFailure>> fetchLogSize(String buildUrl) async =>
      Ok(text.length);

  @override
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  }) async =>
      Ok(LogChunk(text: text, nextOffset: text.length, hasMoreData: false));

  @override
  Future<Result<List<String>?, AppFailure>> fetchTimestamps(
    String buildUrl, {
    required int startLine,
    int? endLine,
  }) async {
    timestampStart = startLine;
    return Ok(timestamps);
  }

  @override
  Future<Result<void, AppFailure>> downloadConsoleText(
    String buildUrl,
    String savePath,
  ) async {
    downloadedTo = savePath;
    File(savePath).writeAsStringSync(text);
    return const Ok(null);
  }
}

(ProviderContainer, _Repo) _setUp(String text) {
  final repo = _Repo(text);
  final container = ProviderContainer(
    overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  container
    ..listen(buildLogNotifierProvider(_url), (_, _) {})
    ..listen(consolePrefsNotifierProvider, (_, _) {});
  return (container, repo);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('prefs persist and reload', () async {
    final (container, _) = _setUp('');
    await container
        .read(consolePrefsNotifierProvider.notifier)
        .update(const ConsolePrefs(wrap: false, fontStep: 2, timestamps: true));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('console_wrap'), isFalse);
    expect(prefs.getInt('console_font_step'), 2);
    expect(prefs.getBool('console_timestamps'), isTrue);
  });

  test('search finds lines and steps through matches, wrapping', () async {
    final (container, _) = _setUp('error one\nok\nERROR two\n');
    container.listen(consoleSearchNotifierProvider(_url), (_, _) {});
    await container.read(buildLogNotifierProvider(_url).future);

    final notifier = container.read(
      consoleSearchNotifierProvider(_url).notifier,
    )..setQuery('error');
    var search = container.read(consoleSearchNotifierProvider(_url));
    expect(search.matches, [0, 2]);
    expect(search.counter, '1 / 2');

    notifier.next();
    search = container.read(consoleSearchNotifierProvider(_url));
    expect(search.currentLine, 2);
    notifier.next();
    expect(container.read(consoleSearchNotifierProvider(_url)).currentLine, 0);
    notifier.previous();
    expect(
      container.read(consoleSearchNotifierProvider(_url)).counter,
      '2 / 2',
    );
  });

  test(
    'timestamps are fetched for exactly the visible lines, by absolute line',
    () async {
      SharedPreferences.setMockInitialValues({'console_timestamps': true});
      final (container, repo) = _setUp('a\nb\nc\n');
      repo.timestamps = ['10:00:01', '10:00:02', '10:00:03'];
      container.listen(consoleTimestampsNotifierProvider(_url), (_, _) {});
      await container.read(buildLogNotifierProvider(_url).future);
      // Let the prefs load from storage, then the timestamps fetch.
      await Future<void>.delayed(Duration.zero);
      final stamps = await container.read(
        consoleTimestampsNotifierProvider(_url).future,
      );

      expect(repo.timestampStart, -3);
      expect(stamps.at(0), '10:00:01');
      expect(stamps.at(2), '10:00:03');
      expect(stamps.at(3), isNull);
    },
  );

  test('a missing Timestamper plugin is reported, not an error', () async {
    SharedPreferences.setMockInitialValues({'console_timestamps': true});
    final (container, repo) = _setUp('a\n');
    repo.timestamps = null;
    container.listen(consoleTimestampsNotifierProvider(_url), (_, _) {});
    await container.read(buildLogNotifierProvider(_url).future);
    await Future<void>.delayed(Duration.zero);

    final stamps = await container.read(
      consoleTimestampsNotifierProvider(_url).future,
    );
    expect(stamps.pluginMissing, isTrue);
  });

  test('save full log downloads, shares, then deletes the temp file', () async {
    final directory = Directory.systemTemp.createTempSync('jt-log');
    addTearDown(() => directory.deleteSync(recursive: true));
    final shared = <String>[];
    final repo = _Repo('full log\n');
    final container = ProviderContainer(
      overrides: [
        jenkinsRepositoryProvider.overrideWithValue(repo),
        tempDirectoryProvider.overrideWith((ref) async => directory),
        fileSharerProvider.overrideWithValue((path, subject) async {
          expect(File(path).readAsStringSync(), 'full log\n');
          shared.add(path);
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(fullLogExportNotifierProvider(_url), (_, _) {});

    await container
        .read(fullLogExportNotifierProvider(_url).notifier)
        .export(fileName: 'Build-3.log');

    expect(shared, ['${directory.path}/Build-3.log']);
    expect(File(shared.single).existsSync(), isFalse, reason: 'no copy kept');
  });
}
