import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/network/jenkins_client_factory.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';

/// Shared helpers for `fixture`-tagged tests: real requests against the
/// fixture Jenkins in `tools/jenkins-fixture/`, through the app's own
/// `buildJenkinsDio` (Basic Auth + CSRF crumb + cookie jar) and
/// `JenkinsRepositoryImpl` — the exact production code path.
class FixtureJenkins {
  FixtureJenkins._(this.url, this.adminToken, this.viewerToken);

  factory FixtureJenkins.fromEnvironment() {
    String read(String name) {
      final value = Platform.environment[name];
      if (value == null || value.isEmpty) {
        throw StateError(
          '$name is not set — run tools/jenkins-fixture/fixture.sh test',
        );
      }
      return value;
    }

    return FixtureJenkins._(
      read('FIXTURE_URL'),
      read('FIXTURE_ADMIN_TOKEN'),
      read('FIXTURE_VIEWER_TOKEN'),
    );
  }

  final String url;
  final String adminToken;
  final String viewerToken;

  Dio adminDio() =>
      buildJenkinsDio(baseUrl: url, username: 'admin', password: adminToken);

  Dio viewerDio() =>
      buildJenkinsDio(baseUrl: url, username: 'viewer', password: viewerToken);

  JenkinsRepositoryImpl adminRepository() => JenkinsRepositoryImpl(adminDio());

  JenkinsRepositoryImpl viewerRepository() =>
      JenkinsRepositoryImpl(viewerDio());

  String jobUrl(String path) => '$url/job/${path.split('/').join('/job/')}/';
}

/// Unwraps an [Ok] or fails the test with the [AppFailure] and its debug
/// detail, so a failing fixture test says *why*.
T expectOk<T>(Result<T, AppFailure> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError(
    'Expected Ok, got ${error.runtimeType}: ${error.message} '
    '(${switch (error) {
      UnexpectedResponseFailure(:final debugMessage) => debugMessage,
      UnknownFailure(:final debugMessage) => debugMessage,
      ServerFailure(:final statusCode) => 'HTTP $statusCode',
      _ => '-',
    }})',
  ),
};

/// Polls [probe] every [interval] until it returns non-null, or throws
/// after [timeout].
Future<T> pollUntil<T extends Object>(
  Future<T?> Function() probe, {
  Duration timeout = const Duration(minutes: 2),
  Duration interval = const Duration(seconds: 1),
  String? description,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final value = await probe();
    if (value != null) return value;
    await Future<void>.delayed(interval);
  }
  throw TimeoutException('Timed out waiting for ${description ?? 'condition'}');
}

/// Triggers [jobPath] and returns its new build once Jenkins has started it.
Future<JenkinsBuild> triggerAndAwaitStart(
  FixtureJenkins jenkins,
  String jobPath, {
  Map<String, String> parameters = const {},
}) async {
  final repository = jenkins.adminRepository();
  final jobUrl = jenkins.jobUrl(jobPath);
  final before = expectOk(await repository.fetchJobDetail(jobUrl));
  final previousNumber = before.lastBuild?.number ?? 0;

  expectOk(
    await repository.triggerBuild(
      jobUrl,
      isParameterized: before.isParameterized,
      parameters: parameters,
    ),
  );

  return pollUntil(() async {
    final job = expectOk(await repository.fetchJobDetail(jobUrl));
    final last = job.lastBuild;
    return (last != null && last.number > previousNumber) ? last : null;
  }, description: '$jobPath to start a new build');
}

/// Waits until [build] is finished and returns its final state.
Future<JenkinsBuild> awaitCompletion(
  FixtureJenkins jenkins,
  String jobPath,
  int buildNumber,
) {
  final repository = jenkins.adminRepository();
  return pollUntil(() async {
    final history = expectOk(
      await repository.fetchJobHistory(jenkins.jobUrl(jobPath)),
    );
    final build = history.where((b) => b.number == buildNumber).firstOrNull;
    return (build != null && !build.building && build.result != null)
        ? build
        : null;
  }, description: '$jobPath #$buildNumber to finish');
}
