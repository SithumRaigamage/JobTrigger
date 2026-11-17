import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/history_entry.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/presentation/features/history/global_history_notifier.dart';
import 'package:job_trigger/presentation/features/history/global_history_screen.dart';

/// P14-09: Global History as redesigned (`UI-UX/screens/08-global-history`).
class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 'a',
    serverName: 'a',
    jenkinsURL: 'https://a.test',
    username: 'u',
    secret: 's',
  );
}

final _now = DateTime.now();

HistoryEntry _entry(String job, String? result, DateTime started) =>
    HistoryEntry(
      jobName: job,
      build: JenkinsBuild(
        number: 4,
        url: 'https://a.test/job/$job/4/',
        timestamp: started.millisecondsSinceEpoch.toDouble(),
        result: result,
        duration: 61000,
      ),
    );

class _History extends GlobalHistoryNotifier {
  @override
  Future<List<HistoryEntry>> build() async => [
    _entry('web', 'FAILURE', _now),
    _entry('api', 'SUCCESS', _now),
    _entry('docs', 'SUCCESS', _now.subtract(const Duration(days: 1))),
  ];
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeServerNotifierProvider.overrideWith(_Server.new),
        globalHistoryNotifierProvider.overrideWith(_History.new),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const GlobalHistoryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('builds are grouped under the day they started', (tester) async {
    await _pump(tester);

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('YESTERDAY'), findsOneWidget);
    expect(find.text('web #4'), findsOneWidget);
    expect(find.text('Failed · 1m 1s'), findsOneWidget);
  });

  testWidgets('a result chip narrows the list', (tester) async {
    await _pump(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Failed'));
    await tester.pumpAndSettle();

    expect(find.text('web #4'), findsOneWidget);
    expect(find.text('api #4'), findsNothing);
    expect(find.text('YESTERDAY'), findsNothing);
  });
}
