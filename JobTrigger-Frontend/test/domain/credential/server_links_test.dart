import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/credential/server_links.dart';

void main() {
  group('jenkinsWebUrl (P19-06)', () {
    test('keeps an https address as it is', () {
      expect(
        jenkinsWebUrl('https://jenkins.example.com/'),
        Uri.parse('https://jenkins.example.com/'),
      );
    });

    test('accepts a plain http LAN address with a port', () {
      expect(
        jenkinsWebUrl('http://192.168.1.24:8080'),
        Uri.parse('http://192.168.1.24:8080'),
      );
    });

    test('keeps a folder page inside the server', () {
      expect(
        jenkinsWebUrl('https://ci.test/job/Projects/job/api/'),
        Uri.parse('https://ci.test/job/Projects/job/api/'),
      );
    });

    test('trims surrounding spaces', () {
      expect(
        jenkinsWebUrl('  https://ci.test  '),
        Uri.parse('https://ci.test'),
      );
    });

    for (final unusable in [
      '',
      'jenkins',
      'ci.test:8080',
      'ftp://ci.test',
      'javascript:alert(1)',
      'http://',
      'https://exa mple.com',
    ]) {
      test('rejects "$unusable"', () {
        expect(jenkinsWebUrl(unusable), isNull);
      });
    }
  });
}
