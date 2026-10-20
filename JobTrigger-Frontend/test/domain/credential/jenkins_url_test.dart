import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/credential/jenkins_url.dart';

void main() {
  group('jenkinsUrlProblem (AUD-14)', () {
    test('accepts https and http addresses, with or without a path', () {
      for (final url in [
        'https://ci.example.com',
        'http://192.168.1.20:8080',
        'https://example.com/jenkins/',
        '  http://jenkins.local  ',
      ]) {
        expect(jenkinsUrlProblem(url), isNull, reason: url);
      }
    });

    test('rejects anything without an http(s) scheme and a host', () {
      expect(jenkinsUrlProblem(''), contains('Enter'));
      expect(jenkinsUrlProblem('ci.example.com'), contains('https://'));
      expect(jenkinsUrlProblem('ftp://ci.example.com'), contains('https://'));
      expect(jenkinsUrlProblem('https://'), contains('host'));
      expect(jenkinsUrlProblem('https://ci.example.com/?a=1'), contains('?'));
    });
  });

  test('normalises spaces and trailing slashes', () {
    expect(
      normalizeJenkinsUrl(' https://ci.example.com/jenkins// '),
      'https://ci.example.com/jenkins',
    );
  });

  test('flags only http as cleartext', () {
    expect(isCleartextUrl('http://jenkins.local:8080'), isTrue);
    expect(isCleartextUrl('HTTP://JENKINS.LOCAL'), isTrue);
    expect(isCleartextUrl('https://ci.example.com'), isFalse);
    expect(isCleartextUrl('not a url'), isFalse);
  });
}
