import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/build_watch.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/presentation/features/open_link/open_link_location.dart';

void main() {
  // AUD-45: a tap never goes straight to job detail on the active server.
  test('a notification payload opens the open-link screen with its server', () {
    final notification = notificationFor(
      const BuildWatch(
        serverId: 'server-b',
        jobUrl: 'https://b.example.com/job/deploy/',
        jobLabel: 'deploy',
        buildNumber: 7,
      ),
      const JenkinsBuild(
        number: 7,
        url: 'https://b.example.com/job/deploy/7/',
        timestamp: 0,
        result: 'SUCCESS',
      ),
    );
    final location = Uri.parse(openLinkLocation(notification.payload));
    expect(location.path, '/open');
    expect(location.queryParameters, {
      'url': 'https://b.example.com/job/deploy/',
      'server': 'server-b',
    });
  });

  test('a pre-upgrade payload (a bare job URL) still opens safely', () {
    final location = Uri.parse(
      openLinkLocation('https://b.example.com/job/deploy/'),
    );
    expect(location.path, '/open');
    expect(location.queryParameters, {
      'url': 'https://b.example.com/job/deploy/',
    });
  });
}
