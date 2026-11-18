import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/package_info_provider.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/repositories/app_info_repository_impl.dart';
import 'package:job_trigger/data/repositories/support_repository_impl.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';
import 'package:job_trigger/domain/app_info/app_info_repository.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/support/support_category.dart';
import 'package:job_trigger/domain/support/support_diagnostics.dart';
import 'package:job_trigger/domain/support/support_repository.dart';
import 'package:job_trigger/domain/support/support_ticket.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/support/support_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u', email: 'sam@acme.dev'));
}

class _Server extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 'a',
    serverName: 'Acme production',
    jenkinsURL: 'https://ci.example.com:8443/job/api',
    username: 'u',
    secret: 's',
  );
}

class _AppInfo implements AppInfoRepository {
  @override
  Future<Result<AppInfo, AppFailure>> fetchAppInfo() async => const Ok(
    AppInfo(
      appVersion: '1.0.0',
      buildNumber: '7',
      supportEmail: 'support@jobtrigger.app',
    ),
  );
}

class _Support implements SupportRepository {
  _Support({this.result});

  final Result<SupportTicket, AppFailure>? result;
  List<SupportTicket> mine = const [];
  int calls = 0;
  SupportCategory? category;
  String? subject;
  String? message;
  String? replyEmail;
  SupportDiagnostics? diagnostics;

  @override
  Future<Result<SupportTicket, AppFailure>> submit({
    required SupportCategory category,
    required String subject,
    required String message,
    String? replyEmail,
    SupportDiagnostics? diagnostics,
  }) async {
    this.category = category;
    this.subject = subject;
    this.message = message;
    this.replyEmail = replyEmail;
    this.diagnostics = diagnostics;
    return result ??
        const Ok(
          SupportTicket(
            id: 't1',
            category: SupportCategory.bug,
            subject: 'Build log blank',
            message: 'Nothing shows.',
            status: 'open',
          ),
        );
  }

  @override
  Future<Result<List<SupportTicket>, AppFailure>> fetchMine() async {
    calls++;
    return Ok(mine);
  }
}

Future<void> _pump(WidgetTester tester, _Support support) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supportRepositoryProvider.overrideWithValue(support),
        appInfoRepositoryProvider.overrideWithValue(_AppInfo()),
        authNotifierProvider.overrideWith(_Auth.new),
        activeServerNotifierProvider.overrideWith(_Server.new),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'JobTrigger',
            packageName: 'app',
            version: '1.0.0',
            buildNumber: '7',
          ),
        ),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: const SupportScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _send(WidgetTester tester) async {
  final button = find.text('Send report');
  // The form scrolls; the button is below the fold and only built once
  // scrolled to.
  await tester.scrollUntilVisible(
    button,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sends a report with only host-level diagnostics', (
    tester,
  ) async {
    final support = _Support();
    await _pump(tester, support);

    await tester.enterText(find.byType(TextField).at(0), 'Build log blank');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Opening the console shows nothing.',
    );
    await _send(tester);

    expect(support.category, SupportCategory.bug);
    expect(support.subject, 'Build log blank');
    expect(support.replyEmail, 'sam@acme.dev');
    expect(support.diagnostics?.appVersion, '1.0.0');
    expect(support.diagnostics?.tool, 'jenkins');
    // The job path and anything else after the host never leaves the app.
    expect(support.diagnostics?.serverHost, 'https://ci.example.com:8443');

    expect(find.text('Report sent'), findsOneWidget);
    expect(find.text('We reply to sam@acme.dev.'), findsOneWidget);
  });

  testWidgets('an empty form names the missing field and sends nothing', (
    tester,
  ) async {
    final support = _Support();
    await _pump(tester, support);

    await _send(tester);

    expect(find.text('Add a short subject.'), findsOneWidget);
    expect(support.subject, isNull);
  });

  testWidgets('a failed send keeps the form and shows the reason', (
    tester,
  ) async {
    final support = _Support(result: const Err(NetworkFailure()));
    await _pump(tester, support);

    await tester.enterText(find.byType(TextField).at(0), 'Build log blank');
    await tester.enterText(find.byType(TextField).at(1), 'Nothing shows.');
    await _send(tester);

    expect(find.textContaining("Can't reach the server"), findsOneWidget);
    expect(find.text('Send report'), findsOneWidget);
    expect(find.text('Report sent'), findsNothing);
  });

  testWidgets('a prefilled tool request starts as a tool request', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportRepositoryProvider.overrideWithValue(_Support()),
          appInfoRepositoryProvider.overrideWithValue(_AppInfo()),
          authNotifierProvider.overrideWith(_Auth.new),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const SupportScreen(category: SupportCategory.toolRequest),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tool request: '), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Tool request'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('pull-to-refresh reloads earlier reports and their status', (
    tester,
  ) async {
    // A tall surface so the form and the reports section are both on screen;
    // this test is about the gesture, not about scrolling.
    tester.view.physicalSize = const Size(1200, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final support = _Support()
      ..mine = const [
        SupportTicket(
          id: 'old1',
          category: SupportCategory.bug,
          subject: 'Console stays blank',
          message: 'Nothing shows.',
          status: 'open',
        ),
      ];
    await _pump(tester, support);

    expect(find.text('Console stays blank'), findsOneWidget);
    expect(find.text('Sent'), findsOneWidget);

    // The owner triages it between visits: the screen must pick that up
    // without being torn down and rebuilt.
    support.mine = const [
      SupportTicket(
        id: 'old1',
        category: SupportCategory.bug,
        subject: 'Console stays blank',
        message: 'Nothing shows.',
        status: 'triaged',
      ),
    ];

    // RefreshIndicator arms only past 25% of the viewport, and the tall
    // surface used above makes that a long pull.
    await tester.drag(find.text('Support'), const Offset(0, 1200));
    await tester.pumpAndSettle();

    expect(find.text('In review'), findsOneWidget);
    expect(find.text('Sent'), findsNothing);
  });
}
