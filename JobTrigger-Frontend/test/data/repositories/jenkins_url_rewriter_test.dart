import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/jenkins/jenkins_job_dto.dart';
import 'package:job_trigger/data/models/jenkins/jenkins_server_info_dto.dart';
import 'package:job_trigger/data/repositories/jenkins_url_rewriter.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';

void main() {
  test(
    'rewrites every url in the tree to the active server, preserving path',
    () {
      // Real fixture from a live Jenkins instance whose internal root URL is
      // an ngrok tunnel, reached in practice via http://localhost:8080 — the
      // exact mismatched-host scenario docs/architecture.md §5 describes.
      final raw = File(
        'test/fixtures/jenkins_tree_fixture.json',
      ).readAsStringSync();
      final serverInfo = JenkinsServerInfoDto.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final jobs = serverInfo.jobs.map((dto) => dto.toDomain()).toList();

      final rewritten = rewriteJobTreeUrls(jobs, 'http://localhost:8080');

      void checkAllUrls(List<JenkinsJob> jobs) {
        for (final job in jobs) {
          final uri = Uri.parse(job.url);
          expect(uri.scheme, 'http');
          expect(uri.host, 'localhost');
          expect(uri.port, 8080);
          // Path is preserved, not collapsed.
          expect(uri.path, startsWith('/job/'));

          if (job.lastBuild != null) {
            final buildUri = Uri.parse(job.lastBuild!.url);
            expect(buildUri.host, 'localhost');
            expect(buildUri.port, 8080);
          }

          if (job.jobs != null) checkAllUrls(job.jobs!);
        }
      }

      checkAllUrls(rewritten);

      // Spot-check one deep path survives intact.
      final projects = rewritten.firstWhere((job) => job.name == 'Projects');
      expect(projects.url, 'http://localhost:8080/job/Projects/');
    },
  );

  test('rewrites to a default-port https URL without an explicit port', () {
    final raw = File(
      'test/fixtures/jenkins_tree_fixture.json',
    ).readAsStringSync();
    final serverInfo = JenkinsServerInfoDto.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    final jobs = serverInfo.jobs.map((dto) => dto.toDomain()).toList();

    final rewritten = rewriteJobTreeUrls(jobs, 'https://jenkins.example.com');

    final projects = rewritten.firstWhere((job) => job.name == 'Projects');
    expect(projects.url, 'https://jenkins.example.com/job/Projects/');
  });
}
