@Tags(['fixture'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/console_decoder.dart';
import 'package:job_trigger/presentation/features/build_log/build_log_notifier.dart';

import 'fixture_support.dart';

/// P11-11 / US-JX-07 against `big-log` (a 50k-iteration ANSI-colored,
/// timestamped log — about 250k lines and 14.7 MB with the `sh -x` trace).
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();

  Future<String> finishedBigLogBuild() async {
    final repository = jenkins.adminRepository();
    final job = expectOk(
      await repository.fetchJobDetail(jenkins.jobUrl('big-log')),
    );
    final last = job.lastBuild;
    if (last != null && !last.building) return last.url;
    final build = await triggerAndAwaitStart(jenkins, 'big-log');
    await awaitCompletion(jenkins, 'big-log', build.number);
    return build.url;
  }

  test('a huge log is sized by HEAD and opened at its tail', () async {
    final repository = jenkins.adminRepository();
    final url = await finishedBigLogBuild();

    final size = expectOk(await repository.fetchLogSize(url));
    expect(size, greaterThan(initialTailBytes * 5));

    final stopwatch = Stopwatch()..start();
    final tail = expectOk(
      await repository.streamBuildLog(url, start: size - initialTailBytes),
    );
    final lines = ConsoleDecoder().addChunk(tail.text);
    stopwatch.stop();

    expect(tail.text.length, lessThan(initialTailBytes * 2));
    expect(lines.last.text, 'Finished: SUCCESS');
    // Colors decoded, console notes gone.
    expect(lines.any((line) => line.text.contains('ha:////')), isFalse);
    final colored = lines.firstWhere((line) => line.text.startsWith('INFO'));
    expect(colored.spans.first.style.foreground, const ConsoleColor.indexed(2));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));
    // Timestamper embeds `[ISO] ` in pipeline logs; it's lifted off the text.
    expect(colored.timestamp, isNotNull);
    expect(lines.any((line) => line.text.startsWith('[20')), isFalse);
  });

  test(
    'timestamps count back from the end and the error marker is found',
    () async {
      final repository = jenkins.adminRepository();
      final url = await finishedBigLogBuild();

      final stamps = expectOk(
        await repository.fetchTimestamps(url, startLine: -2000),
      )!;
      expect(stamps, hasLength(2000));
      expect(
        stamps.where((stamp) => RegExp(r'^\d\d:\d\d:\d\d$').hasMatch(stamp)),
        isNotEmpty,
      );

      final middle = expectOk(
        await repository.streamBuildLog(url, start: 0),
      ).text;
      final all = ConsoleDecoder().addChunk(middle);
      expect(all.indexWhere((line) => isErrorLine(line.text)), isNot(-1));
    },
  );

  test('a job without timestamps() returns an empty list, not a 404', () async {
    final repository = jenkins.adminRepository();
    final job = expectOk(
      await repository.fetchJobDetail(jenkins.jobUrl('freestyle-simple')),
    );
    final stamps = expectOk(
      await repository.fetchTimestamps(job.lastBuild!.url, startLine: -5),
    );
    expect(stamps, isNotNull);
    expect(stamps!.every((stamp) => stamp.trim().isEmpty), isTrue);
  });

  test('save full log streams consoleText to disk', () async {
    final repository = jenkins.adminRepository();
    final url = await finishedBigLogBuild();
    final directory = Directory.systemTemp.createTempSync('jt-console');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/big.log');

    expectOk(await repository.downloadConsoleText(url, file.path));

    expect(file.lengthSync(), greaterThan(10 * 1024 * 1024));
    expect(file.readAsStringSync().trimRight(), endsWith('Finished: SUCCESS'));
  });
}
