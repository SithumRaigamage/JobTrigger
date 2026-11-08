import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_links.dart';

void main() {
  test('a project opens its dashboard', () {
    expect(
      sonarQubeProjectUri('http://192.168.1.53:9000', 'JobTrigger').toString(),
      'http://192.168.1.53:9000/dashboard?id=JobTrigger',
    );
  });

  test('an issue opens in the project issues view', () {
    expect(
      sonarQubeIssueUri(
        'https://sonar.example.com',
        'acme:api',
        'AX-1',
      ).toString(),
      'https://sonar.example.com/project/issues'
      '?id=acme%3Aapi&issues=AX-1&open=AX-1',
    );
  });

  test('a trailing slash is ignored and a server path is kept', () {
    expect(
      sonarQubeProjectUri('https://host/sonar/', 'k').toString(),
      'https://host/sonar/dashboard?id=k',
    );
  });

  test('keys with spaces or symbols are encoded, not broken', () {
    final uri = sonarQubeProjectUri('http://h', 'my project&x=1');
    expect(uri.queryParameters['id'], 'my project&x=1');
    expect(uri.queryParameters.length, 1);
  });
}
