import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/presentation/features/build_log/build_log_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_jenkins_repository.dart';

// Widget coverage for the US-JX-07 console screen (pre-release audit
// 2026-11-20: the viewer, toolbar and notifiers were tested, the screen
// that wires them together was not).

const _build = JenkinsBuild(
  number: 12,
  url: 'https://ci.test/job/demo/12/',
  timestamp: 1793491200000,
);

const _log =
    'Started by user admin\n'
    'Running on agent-1\n'
    '+ npm test\n'
    'ERROR: 2 tests failed\n'
    'Finished: FAILURE\n';

class _Repo extends FakeJenkinsRepository {
  _Repo(this.result);

  Result<LogChunk, AppFailure> result;
  int reads = 0;

  @override
  Future<Result<int, AppFailure>> fetchLogSize(String buildUrl) async =>
      const Ok(_log.length);

  @override
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  }) async {
    reads++;
    return result;
  }
}

Ok<LogChunk, AppFailure> _complete(String text) =>
    Ok(LogChunk(text: text, nextOffset: text.length, hasMoreData: false));

Future<_Repo> _pump(
  WidgetTester tester,
  Result<LogChunk, AppFailure> result,
) async {
  final repo = _Repo(result);
  tester.view
    ..physicalSize = const Size(900, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: BuildLogScreen(jenkinsBuild: _build)),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('BuildLogScreen (US-JX-07)', () {
    testWidgets('shows the build title, line count and the log', (
      tester,
    ) async {
      await _pump(tester, _complete(_log));

      expect(find.text('Console'), findsOneWidget);
      expect(find.text('Build #12 · 5 lines'), findsOneWidget);
      expect(find.textContaining('Started by user admin'), findsWidgets);
      expect(find.textContaining('Finished: FAILURE'), findsWidgets);
      expect(find.text('Jump to first error'), findsOneWidget);
      expect(find.text('Follow'), findsOneWidget);
    });

    testWidgets('copy puts the plain log on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _pump(tester, _complete(_log));

      await tester.tap(find.byTooltip('Copy log'));
      await tester.pump();

      expect(copied, _log.trimRight());
      expect(find.text('Log copied to clipboard'), findsOneWidget);
    });

    // US-LOG-03 "Share via system share sheet": share_plus is handed the
    // loaded log as text.
    testWidgets('share opens the share sheet with the log text', (
      tester,
    ) async {
      const channel = MethodChannel('dev.fluttercommunity.plus/share');
      Map<Object?, Object?>? shared;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'share') {
          shared = call.arguments as Map<Object?, Object?>;
        }
        return 'dev.fluttercommunity.plus/share/unavailable';
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await _pump(tester, _complete(_log));

      await tester.tap(find.byTooltip('Share log'));
      await tester.pump();

      expect(shared?['text'], _log.trimRight());
    });

    testWidgets('search shows the match counter', (tester) async {
      await _pump(tester, _complete(_log));

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // "+ npm test" and "ERROR: 2 tests failed".
      expect(find.text('1 / 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Next match'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('a log without errors says so on Jump to first error', (
      tester,
    ) async {
      await _pump(tester, _complete('all good\nFinished: SUCCESS\n'));

      await tester.tap(find.text('Jump to first error'));
      await tester.pump();

      expect(find.text('No errors found in the loaded log'), findsOneWidget);
    });

    testWidgets('a failure shows the error view; Retry reads again', (
      tester,
    ) async {
      final repo = await _pump(tester, const Err(NetworkFailure()));

      expect(find.text('Retry Connection'), findsOneWidget);
      // Actions that need a log are off until one has loaded.
      final copy = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.copy_rounded),
      );
      expect(copy.onPressed, isNull);

      repo.result = _complete(_log);
      final before = repo.reads;
      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();

      expect(repo.reads, greaterThan(before));
      expect(find.text('Build #12 · 5 lines'), findsOneWidget);
    });
  });
}
