import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_link.dart';

JenkinsServer _server(String id, String url) => JenkinsServer(
  id: id,
  serverName: id,
  jenkinsURL: url,
  username: 'u',
  secret: 's',
);

final _servers = [
  _server('root', 'https://ci.example.com'),
  _server('ctx', 'https://ci.example.com/jenkins/'),
  _server('local', 'http://localhost:8090'),
];

JenkinsLinkTarget _target(String link) =>
    resolveJenkinsLink(link, _servers) as JenkinsLinkTarget;

void main() {
  test('a nested job, a build, and its console', () {
    final target = _target(
      'https://ci.example.com/job/team/job/api/123/console',
    );
    expect(target.server.id, 'root');
    expect(target.jobUrl, 'https://ci.example.com/job/team/job/api/');
    expect(target.jobLabel, 'api');
    expect(target.buildNumber, 123);
    expect(target.showLog, isTrue);
    expect(target.buildUrl, 'https://ci.example.com/job/team/job/api/123/');
  });

  test('the longest matching context path wins', () {
    expect(_target('https://ci.example.com/jenkins/job/a/').server.id, 'ctx');
    expect(
      _target('https://ci.example.com/jenkins/job/a/').jobUrl,
      'https://ci.example.com/jenkins/job/a/',
    );
  });

  test('view prefixes are skipped; job-level pages open the job', () {
    final viaView = _target(
      'https://ci.example.com/view/Pipelines/job/deploy/',
    );
    expect(viaView.jobUrl, 'https://ci.example.com/job/deploy/');
    expect(viaView.buildNumber, isNull);

    final lastBuild = _target('https://ci.example.com/job/deploy/lastBuild/');
    expect(lastBuild.buildNumber, isNull);
  });

  test('multibranch names stay encoded in the URL, decoded in the label', () {
    final target = _target(
      'http://localhost:8090/job/sample-multibranch/job/feature%252Flogin/7/',
    );
    expect(target.jobLabel, 'feature%2Flogin');
    expect(
      target.jobUrl,
      'http://localhost:8090/job/sample-multibranch/job/feature%252Flogin/',
    );
    expect(target.buildNumber, 7);
    expect(target.showLog, isFalse);
  });

  test('problems', () {
    expect(
      resolveJenkinsLink('not a url', _servers),
      JenkinsLinkProblem.invalid,
    );
    expect(
      resolveJenkinsLink('ftp://ci.example.com/job/a/', _servers),
      JenkinsLinkProblem.invalid,
    );
    expect(
      resolveJenkinsLink('https://me:secret@ci.example.com/job/a/', _servers),
      JenkinsLinkProblem.credentialsInUrl,
    );
    expect(
      resolveJenkinsLink('https://other.example.com/job/a/', _servers),
      JenkinsLinkProblem.unknownServer,
    );
    expect(
      resolveJenkinsLink('http://localhost:9999/job/a/', _servers),
      JenkinsLinkProblem.unknownServer,
      reason: 'the port must match too',
    );
    expect(
      resolveJenkinsLink('https://ci.example.com/manage/', _servers),
      JenkinsLinkProblem.notAJob,
    );
  });

  test('jobTriggerLinkFor round-trips the Jenkins URL', () {
    final link = jobTriggerLinkFor('https://ci.example.com/job/a/1/');
    expect(link.scheme, 'jobtrigger');
    expect(link.path, '/open');
    expect(link.queryParameters['url'], 'https://ci.example.com/job/a/1/');
  });
}
