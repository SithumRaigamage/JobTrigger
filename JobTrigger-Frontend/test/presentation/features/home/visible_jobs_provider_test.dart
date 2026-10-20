import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/home/folder_breadcrumb_notifier.dart';
import 'package:job_trigger/presentation/features/home/folder_contents_notifier.dart';
import 'package:job_trigger/presentation/features/home/job_search_notifier.dart';
import 'package:job_trigger/presentation/features/home/visible_jobs_provider.dart';
import 'package:job_trigger/presentation/features/settings/active_server_notifier.dart';

import '../../../support/fake_jenkins_repository.dart';

const _base = 'https://jenkins.test';

JenkinsJob _job(String path, {String? displayName, List<JenkinsJob>? jobs}) =>
    JenkinsJob(
      name: path.split('/').last,
      displayName: displayName,
      url: '$_base/job/${path.split('/').join('/job/')}/',
      jobs: jobs,
    );

/// Serves one level per folder via `fetchFolder`, and the whole nested
/// tree via `fetchJobTree`, counting both.
class _FolderRepository extends FakeJenkinsRepository {
  _FolderRepository(this.folders);

  /// Folder URL (or null for the root) -> its children.
  final Map<String?, List<JenkinsJob>> folders;
  int treeFetches = 0;
  final folderFetches = <String?>[];

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(
    String? folderUrl,
  ) async {
    folderFetches.add(folderUrl);
    return Ok(folders[folderUrl] ?? const []);
  }

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() async {
    treeFetches++;
    List<JenkinsJob> nest(String? url) => [
      for (final job in folders[url] ?? const <JenkinsJob>[])
        folders.containsKey(job.url) ? job.copyWith(jobs: nest(job.url)) : job,
    ];
    return Ok(nest(null));
  }
}

class _StubActiveServer extends ActiveServerNotifier {
  @override
  JenkinsServer? build() => const JenkinsServer(
    id: 's1',
    serverName: 's1',
    jenkinsURL: _base,
    username: 'u',
    secret: 's',
  );
}

final _projects = _job('Projects', jobs: const []);
final _frontend = _job('Projects/frontend', jobs: const []);

Map<String?, List<JenkinsJob>> _server() => {
  null: [_projects, _job('standalone-job')],
  _projects.url: [
    _job('Projects/backend-CI'),
    _frontend,
    _job('Projects/feature%2Flogin', displayName: 'feature/login'),
  ],
  _frontend.url: [_job('Projects/frontend/CI')],
};

(ProviderContainer, _FolderRepository) _setUp([
  Map<String?, List<JenkinsJob>>? folders,
]) {
  final repository = _FolderRepository(folders ?? _server());
  final container = ProviderContainer(
    overrides: [
      jenkinsRepositoryProvider.overrideWithValue(repository),
      activeServerNotifierProvider.overrideWith(_StubActiveServer.new),
    ],
  );
  addTearDown(container.dispose);
  container.listen(visibleJobsProvider, (_, _) {});
  return (container, repository);
}

Future<List<String>> _labels(ProviderContainer container) async {
  // Let the lazily-fetched source settle.
  for (var i = 0; i < 5 && container.read(visibleJobsProvider).isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return container
      .read(visibleJobsProvider)
      .requireValue
      .map((job) => job.label)
      .toList();
}

void main() {
  // The selected view (US-JX-17) is read from shared_preferences.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Home root is one lazy level, never the recursive crawl (AUD-20)',
    () async {
      final (container, repository) = _setUp();

      expect(await _labels(container), ['Projects', 'standalone-job']);
      expect(repository.folderFetches, [null]);
      expect(repository.treeFetches, 0);
    },
  );

  test('entering a folder fetches just that folder', () async {
    final (container, repository) = _setUp();
    await _labels(container);

    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(_projects);

    expect(await _labels(container), [
      'backend-CI',
      'frontend',
      'feature/login',
    ]);
    expect(repository.folderFetches, [null, _projects.url]);
    expect(repository.treeFetches, 0);
  });

  test(
    'going back up uses the cached parent -- no refetch, no spinner',
    () async {
      final (container, repository) = _setUp();
      await _labels(container);
      final breadcrumb = container.read(
        folderBreadcrumbNotifierProvider.notifier,
      )..navigateInto(_projects);
      await _labels(container);

      breadcrumb.navigateBack();

      expect(container.read(visibleJobsProvider).hasValue, isTrue);
      expect(await _labels(container), ['Projects', 'standalone-job']);
      expect(repository.folderFetches, [null, _projects.url]);
    },
  );

  test('refreshing inside a folder shows its new children (AUD-10)', () async {
    final folders = _server();
    final (container, _) = _setUp(folders);
    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(_projects);
    await _labels(container);

    folders[_projects.url] = [_job('Projects/brand-new')];
    await container
        .read(folderContentsNotifierProvider(_projects.url).notifier)
        .refresh();

    expect(await _labels(container), ['brand-new']);
  });

  test('search crawls the whole tree once, ignoring the breadcrumb', () async {
    final (container, repository) = _setUp();
    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(_projects);
    await _labels(container);

    container.read(jobSearchNotifierProvider.notifier).setQuery('ci');

    expect((await _labels(container)).toSet(), {'backend-CI', 'CI'});
    expect(repository.treeFetches, 1);
  });

  test('search matches the display label and is case-insensitive', () async {
    final (container, _) = _setUp();

    container.read(jobSearchNotifierProvider.notifier).setQuery('FEATURE/');

    expect(await _labels(container), ['feature/login']);
  });
}
