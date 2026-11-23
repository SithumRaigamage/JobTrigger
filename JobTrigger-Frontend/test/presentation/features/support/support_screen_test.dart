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
import 'dart:convert';
import 'dart:typed_data';

import 'package:job_trigger/domain/support/support_area.dart';
import 'package:job_trigger/domain/support/support_category.dart';
import 'package:job_trigger/domain/support/support_diagnostics.dart';
import 'package:job_trigger/domain/support/support_impact.dart';
import 'package:job_trigger/domain/support/support_repository.dart';
import 'package:job_trigger/domain/support/support_screenshot.dart';
import 'package:job_trigger/domain/support/support_ticket.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/support/support_screen.dart';
import 'package:job_trigger/presentation/features/support/support_screenshots.dart';
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
  List<SupportArea> areas = const [];
  SupportImpact impact = SupportImpact.minor;
  List<SupportScreenshot> screenshots = const [];

  @override
  Future<Result<SupportTicket, AppFailure>> submit({
    required SupportCategory category,
    required String subject,
    required String message,
    String? replyEmail,
    SupportDiagnostics? diagnostics,
    List<SupportArea> areas = const [],
    SupportImpact impact = SupportImpact.minor,
    List<SupportScreenshot> screenshots = const [],
  }) async {
    this.category = category;
    this.subject = subject;
    this.message = message;
    this.replyEmail = replyEmail;
    this.diagnostics = diagnostics;
    this.areas = areas;
    this.impact = impact;
    this.screenshots = screenshots;
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

Future<void> _pump(
  WidgetTester tester,
  _Support support, {
  SupportScreenshotPicker? picker,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supportRepositoryProvider.overrideWithValue(support),
        if (picker != null)
          supportScreenshotPickerProvider.overrideWithValue(picker),
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

/// The extra P31 fields sit below the reply email; move them into view.
Future<void> _scrollBy(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(Scrollable).first, Offset(0, dy));
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

class _Picked implements PickedSupportScreenshot {
  const _Picked(this.bytes);

  final Uint8List bytes;

  @override
  String get name => 'shot.png';

  @override
  int get sizeBytes => bytes.length;

  @override
  Future<Uint8List> Function() get read =>
      () async => bytes;
}

// A real 1×1 PNG: the preview must decode, not just pass the magic-byte check.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==',
);

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
    expect(find.text('Ticket t1'), findsOneWidget);
  });

  // US-SUP-01/05: seven kinds, optional areas, impact, and the token warning.
  testWidgets('the form offers the report options and warns about tokens', (
    tester,
  ) async {
    await _pump(tester, _Support());

    for (final kind in [
      'Bug',
      'Feature idea',
      'Question',
      'Tool request',
      'Account & sign-in',
      'Billing & subscription',
      'Something else',
    ]) {
      expect(find.widgetWithText(ChoiceChip, kind), findsOneWidget);
    }
    expect(
      find.textContaining('Do not paste tokens or passwords.'),
      findsOneWidget,
    );
    await _scrollBy(tester, -550);
    for (final area in [
      'Jenkins',
      'GitHub Actions',
      'SonarQube',
      'Website',
      'Phone/app',
      'Account',
    ]) {
      expect(find.widgetWithText(ChoiceChip, area), findsOneWidget);
    }
    expect(find.text('Impact'), findsOneWidget);
    await _scrollBy(tester, -450);
    expect(
      find.textContaining('Blur tokens, passwords and personal data'),
      findsOneWidget,
    );
    final attach = find.widgetWithText(SwitchListTile, 'Attach app details');
    await tester.scrollUntilVisible(
      attach,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<SwitchListTile>(attach).value, isTrue);
    final summary = tester
        .widgetList<Text>(
          find.descendant(of: attach, matching: find.byType(Text)),
        )
        .map((t) => t.data ?? '')
        .join('\n');
    expect(summary, contains('1.0.0'));
    expect(summary, contains('ci.example.com:8443'));
    expect(summary, isNot(contains('/job/api')));
    expect(summary, isNot(contains('Acme production')));
  });

  testWidgets('details are required too', (tester) async {
    final support = _Support();
    await _pump(tester, support);

    await tester.enterText(find.byType(TextField).at(0), 'Build log blank');
    await _send(tester);

    expect(find.text('Describe the issue or request.'), findsOneWidget);
    expect(support.subject, isNull);
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
    // US-SUP-01: what was typed is still there to send again.
    await tester.scrollUntilVisible(
      find.text('Build log blank'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Build log blank'), findsOneWidget);
    expect(find.text('Nothing shows.'), findsOneWidget);
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

  // US-SUP-02: each earlier report shows its status and date.
  testWidgets('earlier reports show status and date', (tester) async {
    tester.view.physicalSize = const Size(1200, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final created = DateTime(2026, 11, 20, 12);
    final support = _Support()
      ..mine = [
        SupportTicket(
          id: 'old1',
          category: SupportCategory.bug,
          subject: 'Console stays blank',
          message: 'Nothing shows.',
          status: 'closed',
          createdAt: created,
        ),
      ];
    await _pump(tester, support);

    expect(find.text('Console stays blank'), findsOneWidget);
    expect(find.text('Closed · 2026-11-20'), findsOneWidget);
  });

  // US-SUP-05/06: the selections and previewed screenshot reach the fake
  // repository, and the draft is cleared after a successful send.
  testWidgets('sends areas, impact and a screenshot', (tester) async {
    final support = _Support();
    await _pump(tester, support, picker: () async => _Picked(_png));

    await tester.enterText(find.byType(TextField).at(0), 'Actions log blank');
    await tester.enterText(find.byType(TextField).at(1), 'No output shown.');
    await _scrollBy(tester, -550);
    await tester.tap(find.widgetWithText(ChoiceChip, 'GitHub Actions'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Minor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blocked').last);
    await tester.pumpAndSettle();
    await _scrollBy(tester, -450);

    await tester.tap(find.text('Add screenshot'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);

    await _send(tester);

    expect(support.areas, [SupportArea.github]);
    expect(support.impact, SupportImpact.blocked);
    expect(support.screenshots, hasLength(1));
    expect(support.screenshots.single.bytes, _png);
    expect(find.text('Report sent'), findsOneWidget);
  });

  testWidgets('a bad screenshot is refused and a good one can be removed', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      _Support(),
      picker: () async {
        calls += 1;
        if (calls == 1) {
          return _Picked(Uint8List.fromList([1, 2, 3]));
        }
        return _Picked(_png);
      },
    );
    await _scrollBy(tester, -1000);
    await tester.tap(find.text('Add screenshot'));
    await tester.pumpAndSettle();
    expect(find.text('Screenshots must be JPG or PNG images.'), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await tester.tap(find.text('Add screenshot'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
  });
}
