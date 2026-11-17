import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_links.dart';

void main() {
  group('deep link (US-SQ-LINK-02)', () {
    test('carries the project key and nothing else', () {
      final link = sonarQubeAppLink('acme:api');
      expect(
        link.toString(),
        'jobtrigger://app/sonarqube/project?key=acme%3Aapi',
      );
      expect(link.queryParameters.keys, ['key']);
    });

    test('accepts real keys and refuses anything else', () {
      for (final ok in ['web', 'acme:api', 'a.b-c_d', 'jt-sample']) {
        expect(sonarQubeLinkKeyIsValid(ok), isTrue, reason: ok);
      }
      for (final bad in [
        null,
        '',
        'two words',
        'http://evil.example/x',
        'a/b',
        'key\nnewline',
        'x' * 401,
      ]) {
        expect(sonarQubeLinkKeyIsValid(bad), isFalse, reason: '$bad');
      }
    });
  });

  group('share text (US-SQ-ISSUES-04)', () {
    test('has message, rule, location and the web link', () {
      final text = sonarQubeIssueShareText(
        projectName: 'JT Sample',
        message: 'Remove this eval',
        typeLabel: 'Bug',
        severityLabel: 'Major',
        rule: 'javascript:S1523',
        ruleName: 'Dynamic code execution',
        location: 'src/app.js:6',
        link: sonarQubeIssueUri('http://sonar.test', 'jt-sample', 'AZ1'),
      );
      expect(text, contains('Remove this eval'));
      expect(text, contains('Rule: javascript:S1523 — Dynamic code execution'));
      expect(text, contains('Where: src/app.js:6'));
      expect(text, contains('http://sonar.test/project/issues?'));
      expect(text, isNot(contains('token')));
    });

    test('leaves out what is unknown', () {
      final text = sonarQubeIssueShareText(
        projectName: 'P',
        message: 'm',
        typeLabel: 'Bug',
        severityLabel: 'Info',
        link: Uri.parse('http://s'),
      );
      expect(text, isNot(contains('Rule:')));
      expect(text, isNot(contains('Where:')));
    });
  });
}
