import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/credentials/active_server_notifier.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/home/home_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../../support/fake_jenkins_repository.dart';

// P19-07: the Home header's server chip drops down the saved servers to
// switch between, instead of jumping to Settings.

const _production = JenkinsServer(
  id: 'a',
  serverName: 'Acme production',
  jenkinsURL: 'https://prod.test',
  username: 'u',
  secret: 's',
  isDefault: true,
);
const _staging = JenkinsServer(
  id: 'b',
  serverName: 'Acme staging',
  jenkinsURL: 'https://staging.test',
  username: 'u',
  secret: 's',
);
const _expired = JenkinsServer(
  id: 'c',
  serverName: 'Old server',
  jenkinsURL: 'https://old.test',
  username: 'u',
  secret: '',
  needsReentry: true,
);

/// Lists a different job per server, so a switch is visible in the list.
class _Repository extends FakeJenkinsRepository {
  _Repository(this.container);

  final ProviderContainer Function() container;

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(
    String? folderUrl,
  ) async {
    final active = container().read(activeServerNotifierProvider);
    return Ok([
      JenkinsJob(name: 'job-of-${active?.id}', url: 'https://x.test/job/a/'),
    ]);
  }
}

class _Credentials extends CredentialsNotifier {
  @override
  Future<List<JenkinsServer>> build() async => [
    _production,
    _staging,
    _expired,
  ];
}

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  Future<ProviderContainer> pumpHome(WidgetTester tester) async {
    late final ProviderContainer container;
    container = ProviderContainer(
      overrides: [
        credentialsNotifierProvider.overrideWith(_Credentials.new),
        jenkinsRepositoryProvider.overrideWithValue(
          _Repository(() => container),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, _) => const Scaffold(body: Text('settings')),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(RegExp('^Server ')));
    await tester.pumpAndSettle();
  }

  testWidgets('the menu lists every saved server and marks the active one', (
    tester,
  ) async {
    await pumpHome(tester);
    await openMenu(tester);

    for (final name in ['Acme staging', 'Old server']) {
      expect(find.text(name), findsOneWidget);
    }
    // The active server is also named by the chip itself.
    expect(find.text('Acme production'), findsNWidgets(2));
    expect(find.text('https://staging.test'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Manage servers…'), findsOneWidget);
    expect(
      find.text('Secret needs re-entering'),
      findsOneWidget,
      reason: 'only for the server that needs it',
    );
  });

  testWidgets('choosing a server switches to it without leaving Home', (
    tester,
  ) async {
    final container = await pumpHome(tester);
    expect(find.text('job-of-a'), findsOneWidget);

    await openMenu(tester);
    await tester.tap(find.text('Acme staging'));
    await tester.pumpAndSettle();

    expect(container.read(activeServerNotifierProvider)?.id, 'b');
    expect(find.text('job-of-b'), findsOneWidget);
    expect(find.text('job-of-a'), findsNothing);
    expect(find.text('settings'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('^Server Acme staging')), findsOne);
  });

  testWidgets('choosing the active server again changes nothing', (
    tester,
  ) async {
    final container = await pumpHome(tester);

    await openMenu(tester);
    await tester.tap(find.text('Acme production').last);
    await tester.pumpAndSettle();

    expect(container.read(activeServerNotifierProvider)?.id, 'a');
    expect(find.text('job-of-a'), findsOneWidget);
  });

  testWidgets('"Manage servers…" goes to Settings', (tester) async {
    await pumpHome(tester);

    await openMenu(tester);
    await tester.tap(find.text('Manage servers…'));
    await tester.pumpAndSettle();

    expect(find.text('settings'), findsOneWidget);
  });
}
