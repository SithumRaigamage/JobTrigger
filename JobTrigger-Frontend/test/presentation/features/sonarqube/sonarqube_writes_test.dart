import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/cache/server_safety_store.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/safety/server_safety.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue_actions.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_issue_actions.dart';

import '../../../support/sonarqube_insights_defaults.dart';

const _issue = SonarQubeIssue(
  key: 'i1',
  type: 'BUG',
  severity: 'MAJOR',
  message: 'Remove this eval',
  file: 'a.js',
  line: 1,
);

/// A fake server whose state only changes when a write is *accepted*.
class _Repo with SonarQubeInsightsDefaults implements SonarQubeRepository {
  String status = 'OPEN';
  String? assignee;
  final comments = <String>[];
  AppFailure? refuse;
  Completer<void>? hold;
  final calls = <String>[];

  @override
  Future<Result<SonarQubeIssueDetail, AppFailure>> fetchIssueDetail(
    String issueKey,
  ) async => Ok(
    SonarQubeIssueDetail(
      status: status,
      assignee: assignee,
      // Only what the server offers from this state.
      transitions: status == 'OPEN' ? ['confirm', 'falsepositive'] : ['reopen'],
      comments: [
        for (final c in comments) SonarQubeIssueComment(login: 'me', text: c),
      ],
    ),
  );

  Future<Result<void, AppFailure>> _write(
    String call,
    void Function() apply,
  ) async {
    calls.add(call);
    await hold?.future;
    if (refuse != null) return Err(refuse!);
    apply();
    return const Ok(null);
  }

  @override
  Future<Result<void, AppFailure>> assignIssue(String issueKey, String a) =>
      _write(
        'assign:$a',
        () => assignee = a.isEmpty ? null : (a == '_me' ? 'admin' : a),
      );

  @override
  Future<Result<void, AppFailure>> transitionIssue(String issueKey, String t) =>
      _write(
        'transition:$t',
        () => status = t == 'confirm' ? 'CONFIRMED' : 'FALSE_POSITIVE',
      );

  @override
  Future<Result<void, AppFailure>> addIssueComment(
    String issueKey,
    String text,
  ) => _write('comment', () => comments.add(text));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [sonarQubeRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: SonarQubeIssueManageCard(issue: _issue),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the server\'s status and only the transitions it offers '
      '(US-SQ-WRITE-02)', (tester) async {
    await _pump(tester, _Repo());
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Unassigned'), findsOneWidget);

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Mark as false positive'), findsOneWidget);
    expect(find.text('Resolve as fixed'), findsNothing);
  });

  testWidgets('a status change asks first, and cancelling sends nothing', (
    tester,
  ) async {
    final repo = _Repo();
    await _pump(tester, repo);
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as false positive'));
    await tester.pumpAndSettle();
    expect(find.text('Mark as false positive?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('the screen changes only after the server has answered '
      '(US-SQ-WRITE-02)', (tester) async {
    final repo = _Repo()..hold = Completer<void>();
    await _pump(tester, repo);
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pump();

    // In flight: still the old status, and the controls are busy.
    expect(repo.calls, ['transition:confirm']);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Confirmed'), findsNothing);

    repo.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Open'), findsNothing);
  });

  testWidgets('a 403 shows the clear message and changes nothing', (
    tester,
  ) async {
    final repo = _Repo()..refuse = const SonarQubeWriteDeniedFailure();
    await _pump(tester, repo);
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Assign'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("isn't allowed to make this change"),
      findsOneWidget,
    );
    expect(find.text('Unassigned'), findsOneWidget);
    expect(repo.assignee, isNull);
  });

  testWidgets('assigning to me uses the id assign understands (found live)', (
    tester,
  ) async {
    final repo = _Repo();
    await _pump(tester, repo);
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Assign'));
    await tester.pumpAndSettle();

    expect(repo.calls, ['assign:_me']);
    expect(find.text('admin'), findsOneWidget);
  });

  testWidgets('a comment warns it is public, is cleared only once saved '
      '(US-SQ-WRITE-03)', (tester) async {
    final repo = _Repo()..refuse = const SonarQubeWriteDeniedFailure();
    await _pump(tester, repo);
    expect(find.text('Visible to everyone on this project.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Looks like a false alarm & more',
    );
    await tester.tap(find.text('Post comment'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pumpAndSettle();
    // Refused: the text stays so nothing is lost.
    expect(find.text('Looks like a false alarm & more'), findsOneWidget);

    repo.refuse = null;
    await tester.tap(find.text('Post comment'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Post'));
    await tester.pumpAndSettle();
    expect(repo.comments, ['Looks like a false alarm & more']);
    // Now it is a saved comment from the server, and the field is empty.
    expect(find.byType(TextField), findsOneWidget);
    expect(
      (tester.widget(find.byType(TextField)) as TextField).controller!.text,
      isEmpty,
    );
  });

  testWidgets('PI-01: a read-only credential disables all issue writes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _Repo();
    await tester.pumpWidget(
      ProviderScope(
        retry: (retryCount, error) => null,
        overrides: [
          sonarQubeRepositoryProvider.overrideWithValue(repo),
          activeSonarQubeCredentialNotifierProvider.overrideWith(
            _ActiveSonarQube.new,
          ),
          serverSafetyNotifierProvider.overrideWithValue(
            const ServerSafety(readOnly: {'sonarqube:sq1'}),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SonarQubeIssueManageCard(issue: _issue),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('read-only on this device'), findsOneWidget);
    // Both write affordances are disabled; not even the dialogs open.
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Change'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Assign'))
          .onPressed,
      isNull,
    );
    final comment = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Post comment'),
    );
    expect(comment.onPressed, isNull);
    expect(repo.calls, isEmpty);
  });
}

class _ActiveSonarQube extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => const SonarQubeCredential(
    id: 'sq1',
    label: 'L',
    baseUrl: 'http://sonar.example:9000',
    secret: 'squ_secret',
  );
}
