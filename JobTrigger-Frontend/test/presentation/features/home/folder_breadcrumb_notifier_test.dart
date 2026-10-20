import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/home/folder_breadcrumb_notifier.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';

JenkinsJob _folder(String name, {String? displayName}) => JenkinsJob(
  name: name,
  displayName: displayName,
  url: 'https://jenkins.test/job/$name/',
  jobs: const [],
);

JenkinsJob _leaf(String name) =>
    JenkinsJob(name: name, url: 'https://jenkins.test/job/$name/');

JenkinsServer _server(String id) => JenkinsServer(
  id: id,
  serverName: id,
  jenkinsURL: 'https://$id.test',
  username: 'u',
  secret: 's',
);

/// A synchronous active server, so tests never trigger the real
/// credentials rehydration (a backend call).
class _StubActiveServer extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => _server('a');

  @override
  Future<void> setActiveServer(JenkinsServer server) async => state = server;
}

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
      activeServerNotifierProvider.overrideWith(_StubActiveServer.new),
    ],
  );
  addTearDown(container.dispose);
  container.listen(folderBreadcrumbNotifierProvider, (_, _) {});
  return container;
}

void main() {
  // The selected view (US-JX-17) is read from shared_preferences.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('initial state is an empty breadcrumb', () {
    expect(_container().read(folderBreadcrumbNotifierProvider), isEmpty);
  });

  test('navigateInto pushes a folder reference with its display label', () {
    final container = _container();

    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(_folder('feature%2Flogin', displayName: 'feature/login'));

    expect(container.read(folderBreadcrumbNotifierProvider), const [
      FolderRef(
        url: 'https://jenkins.test/job/feature%2Flogin/',
        label: 'feature/login',
      ),
    ]);
  });

  test('a folder is recognised by class even when its jobs were not fetched', () {
    final container = _container();
    const multibranch = JenkinsJob(
      name: 'api',
      url: 'https://jenkins.test/job/api/',
      jobClass:
          'org.jenkinsci.plugins.workflow.multibranch.WorkflowMultiBranchProject',
    );

    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(multibranch);

    expect(container.read(folderBreadcrumbNotifierProvider), hasLength(1));
  });

  test('navigateInto on a non-folder job is a no-op', () {
    final container = _container();

    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(_leaf('standalone-job'));

    expect(container.read(folderBreadcrumbNotifierProvider), isEmpty);
  });

  test('navigateBack pops the last folder off the breadcrumb', () {
    final container = _container();
    container.read(folderBreadcrumbNotifierProvider.notifier)
      ..navigateInto(_folder('Projects'))
      ..navigateInto(_folder('frontend'))
      ..navigateBack();

    expect(
      container.read(folderBreadcrumbNotifierProvider).map((f) => f.label),
      ['Projects'],
    );
  });

  test('navigateBack on an empty breadcrumb is a no-op', () {
    final container = _container();

    container.read(folderBreadcrumbNotifierProvider.notifier).navigateBack();

    expect(container.read(folderBreadcrumbNotifierProvider), isEmpty);
  });

  test('reset clears the breadcrumb back to empty', () {
    final container = _container();
    container.read(folderBreadcrumbNotifierProvider.notifier)
      ..navigateInto(_folder('Projects'))
      ..reset();

    expect(container.read(folderBreadcrumbNotifierProvider), isEmpty);
  });

  test('switching the active server resets to the root (AUD-10)', () async {
    final container = _container();
    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(_folder('Projects'));
    expect(container.read(folderBreadcrumbNotifierProvider), hasLength(1));

    await container
        .read(activeServerNotifierProvider.notifier)
        .setActiveServer(_server('b'));

    expect(container.read(folderBreadcrumbNotifierProvider), isEmpty);
  });
}
