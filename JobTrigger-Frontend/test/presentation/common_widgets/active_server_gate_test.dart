import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/no_retry.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/common_widgets/active_server_gate.dart';

class _Servers extends CredentialsNotifier {
  _Servers(this._load);

  final Future<List<JenkinsServer>> Function() _load;

  @override
  Future<List<JenkinsServer>> build() => _load();
}

Future<void> _pump(
  WidgetTester tester,
  Future<List<JenkinsServer>> Function() load,
) => tester.pumpWidget(
  ProviderScope(
    // As in the app: no automatic retries.
    retry: noRetry,
    overrides: [credentialsNotifierProvider.overrideWith(() => _Servers(load))],
    child: const MaterialApp(
      home: Scaffold(body: Center(child: ActiveServerGate())),
    ),
  ),
);

void main() {
  testWidgets('shows a spinner, not "no server", while the list loads', (
    tester,
  ) async {
    final pending = Completer<List<JenkinsServer>>();
    await _pump(tester, () => pending.future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No Jenkins Server'), findsNothing);
  });

  testWidgets('shows "no server" only once the list is empty', (tester) async {
    await _pump(tester, () async => const []);
    await tester.pump();
    await tester.pump();

    expect(find.text('No Jenkins Server'), findsOneWidget);
  });

  testWidgets('shows the error, with a retry, when the list fails', (
    tester,
  ) async {
    await _pump(tester, () async => throw const NetworkFailure());
    await tester.pump();
    await tester.pump();

    expect(find.text('No Jenkins Server'), findsNothing);
    expect(find.text('Retry Connection'), findsOneWidget);
  });
}
