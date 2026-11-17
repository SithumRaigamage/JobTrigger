import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/demo/demo_sonarqube_repository.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_server_info.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_server_screen.dart';

class _Repo extends DemoSonarQubeRepository {
  _Repo({this.result});

  Result<SonarQubeServerInfo, AppFailure>? result;

  @override
  Future<Result<SonarQubeServerInfo, AppFailure>> fetchServerInfo() async =>
      result ?? super.fetchServerInfo();
}

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [sonarQubeRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SonarQubeServerScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('server info (US-SQ-SERVER-01)', () {
    testWidgets('shows the version and the status', (tester) async {
      await _pump(tester, _Repo());

      expect(find.text('10.6.0.92116'), findsOneWidget);
      expect(find.text('Up'), findsOneWidget);
      // Edition needs admin rights, so the page says why it is absent.
      expect(find.textContaining('Edition is not shown'), findsOneWidget);
    });

    testWidgets('a server that is starting explains itself', (tester) async {
      await _pump(
        tester,
        _Repo(
          result: const Ok(
            SonarQubeServerInfo(version: '10.6.0', status: 'STARTING'),
          ),
        ),
      );

      expect(find.text('Starting'), findsOneWidget);
      expect(find.textContaining('The server is starting'), findsOneWidget);
    });

    testWidgets('an unreachable server shows the error with retry', (
      tester,
    ) async {
      await _pump(tester, _Repo(result: const Err(NetworkFailure())));

      expect(find.textContaining('Retry'), findsWidgets);
    });
  });
}
