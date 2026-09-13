import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/jenkins/jenkins_job_dto.dart';
import 'package:job_trigger/data/models/jenkins/jenkins_server_info_dto.dart';

void main() {
  test('recursive jobs parsing works against a real multi-folder fixture', () {
    final raw = File(
      'test/fixtures/jenkins_tree_fixture.json',
    ).readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final serverInfo = JenkinsServerInfoDto.fromJson(json);

    expect(serverInfo.jobs, hasLength(2));
    final projects = serverInfo.jobs.firstWhere(
      (job) => job.name == 'Projects',
    );
    final test = serverInfo.jobs.firstWhere((job) => job.name == 'TEST');

    // Top-level folders: "jobs" key present -> isFolder should read true via
    // the domain entity.
    expect(projects.toDomain().isFolder, isTrue);
    expect(test.toDomain().isFolder, isTrue);

    // Leaf jobs (no "jobs" key at all in the source JSON) must decode to a
    // genuinely null `jobs` list, not an empty one -- this is exactly the
    // @Default([]) pitfall documented in jenkins_job_dto.dart.
    final testPipeline = test.jobs!.first;
    expect(testPipeline.name, 'test-pipeline');
    expect(testPipeline.jobs, isNull);
    expect(testPipeline.toDomain().isFolder, isFalse);
    expect(testPipeline.color, 'blue');
    expect(testPipeline.lastBuild?.result, 'SUCCESS');

    // A folder with an explicit empty "jobs": [] must stay a folder (empty
    // list is not null).
    final helloWorld = projects.jobs!.firstWhere(
      (job) => job.name == 'Hello-World-Node-JS',
    );
    final cdFolder = helloWorld.jobs!.firstWhere((job) => job.name == 'CD');
    expect(cdFolder.jobs, isNotNull);
    expect(cdFolder.jobs, isEmpty);
    expect(cdFolder.toDomain().isFolder, isTrue);

    // Deep recursion: Projects > expensive-tracker > expensive-tracker-backend
    // > CI-Pipleine > expensive-tracker-backend-CI (4 folder levels deep).
    final expensiveTracker = projects.jobs!.firstWhere(
      (job) => job.name == 'expensive-tracker',
    );
    final backend = expensiveTracker.jobs!.firstWhere(
      (job) => job.name == 'expensive-tracker-backend',
    );
    final ciPipeline = backend.jobs!.firstWhere(
      (job) => job.name == 'CI-Pipleine',
    );
    final leaf = ciPipeline.jobs!.firstWhere(
      (job) => job.name == 'expensive-tracker-backend-CI',
    );
    expect(leaf.jobs, isNull);
    expect(leaf.color, 'blue');

    // A job that has never built: lastBuild is null, color is "notbuilt".
    final frontend = expensiveTracker.jobs!.firstWhere(
      (job) => job.name == 'expensive-tracker-frontend',
    );
    final frontendCiFolder = frontend.jobs!.firstWhere(
      (job) => job.name == 'CI-Pipleine',
    );
    final neverBuilt = frontendCiFolder.jobs!.firstWhere(
      (job) => job.name == 'expensive-tracker-frontend-CI',
    );
    expect(neverBuilt.lastBuild, isNull);
    expect(neverBuilt.color, 'notbuilt');
  });
}
