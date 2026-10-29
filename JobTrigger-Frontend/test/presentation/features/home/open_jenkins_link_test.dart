import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/link_launcher.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/home/folder_breadcrumb_notifier.dart';
import 'package:job_trigger/presentation/features/home/home_screen.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../../support/fake_jenkins_repository.dart';

// P19-06: Home's ⋮ → "Open Jenkins link" opens the server in the browser,
// instead of asking for a pasted URL.

const _folder = JenkinsJob(
  name: 'Projects',
  url: 'https://jenkins.test/job/Projects/',
  jobs: [],
);

class _Repository extends FakeJenkinsRepository {
  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(
    String? folderUrl,
  ) async => const Ok([_folder]);
}

class _Credentials extends CredentialsNotifier {
  _Credentials(this._servers);

  final List<JenkinsServer> _servers;

  @override
  Future<List<JenkinsServer>> build() async => _servers;
}

JenkinsServer _server(String url) => JenkinsServer(
  id: 's1',
  serverName: 'Test Server',
  jenkinsURL: url,
  username: 'user',
  secret: 'secret',
);

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  Future<ProviderContainer> pumpHome(
    WidgetTester tester, {
    required String serverUrl,
    required List<Uri> opened,
  }) async {
    final container = ProviderContainer(
      overrides: [
        jenkinsRepositoryProvider.overrideWithValue(_Repository()),
        credentialsNotifierProvider.overrideWith(
          () => _Credentials([_server(serverUrl)]),
        ),
        linkLauncherProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(currentToastProvider, (_, _) {});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> chooseOpenJenkinsLink(WidgetTester tester) async {
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Jenkins link'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens the active server in the browser, with no dialog', (
    tester,
  ) async {
    final opened = <Uri>[];
    await pumpHome(
      tester,
      serverUrl: 'http://192.168.1.24:8080',
      opened: opened,
    );

    await chooseOpenJenkinsLink(tester);

    expect(opened, [Uri.parse('http://192.168.1.24:8080')]);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(TextField), findsOneWidget, reason: 'only the search');
  });

  testWidgets('inside a folder it opens that folder\'s page', (tester) async {
    final opened = <Uri>[];
    final container = await pumpHome(
      tester,
      serverUrl: 'https://jenkins.test',
      opened: opened,
    );
    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(_folder);
    await tester.pumpAndSettle();

    await chooseOpenJenkinsLink(tester);

    expect(opened, [Uri.parse(_folder.url)]);
  });

  testWidgets('an unusable server address says so instead of opening', (
    tester,
  ) async {
    final opened = <Uri>[];
    final container = await pumpHome(
      tester,
      serverUrl: 'jenkins',
      opened: opened,
    );

    await chooseOpenJenkinsLink(tester);

    expect(opened, isEmpty);
    expect(container.read(currentToastProvider)?.title, "Couldn't open link");
    await tester.pump(const Duration(seconds: 4)); // toast auto-dismiss
  });
}
