import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/home/folder_breadcrumb_notifier.dart';

JenkinsJob _folder(String name, {List<JenkinsJob> jobs = const []}) =>
    JenkinsJob(name: name, url: 'https://jenkins.test/job/$name/', jobs: jobs);

JenkinsJob _leaf(String name) =>
    JenkinsJob(name: name, url: 'https://jenkins.test/job/$name/');

void main() {
  test('initial state is an empty breadcrumb', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(folderBreadcrumbNotifierProvider), isEmpty);
  });

  test('navigateInto pushes a folder onto the breadcrumb', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final folder = _folder('Projects');

    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(folder);

    expect(container.read(folderBreadcrumbNotifierProvider), [folder]);
  });

  test('navigateInto on a non-folder job is a no-op', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final leaf = _leaf('standalone-job');

    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(leaf);

    expect(container.read(folderBreadcrumbNotifierProvider), isEmpty);
  });

  test('navigateBack pops the last folder off the breadcrumb', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final projects = _folder('Projects');
    final frontend = _folder('frontend');
    final notifier = container.read(
      folderBreadcrumbNotifierProvider.notifier,
    );
    notifier.navigateInto(projects);
    notifier.navigateInto(frontend);

    notifier.navigateBack();

    expect(container.read(folderBreadcrumbNotifierProvider), [projects]);
  });

  test('navigateBack on an empty breadcrumb is a no-op', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(folderBreadcrumbNotifierProvider.notifier).navigateBack();

    expect(container.read(folderBreadcrumbNotifierProvider), isEmpty);
  });

  test('reset clears the breadcrumb back to empty', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(
      folderBreadcrumbNotifierProvider.notifier,
    );
    notifier.navigateInto(_folder('Projects'));

    notifier.reset();

    expect(container.read(folderBreadcrumbNotifierProvider), isEmpty);
  });
}
