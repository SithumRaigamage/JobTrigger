import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/credential/sonarqube_url.dart';

void main() {
  group('sonarQubeUrlProblem (AUD-52)', () {
    test('accepts SonarCloud and a self-hosted server', () {
      expect(sonarQubeUrlProblem('https://sonarcloud.io'), isNull);
      expect(sonarQubeUrlProblem('http://sonar.lan:9000/sonar/'), isNull);
    });

    test('names what is wrong', () {
      expect(sonarQubeUrlProblem(''), 'Enter the SonarQube URL.');
      expect(sonarQubeUrlProblem('sonar.example.com'), contains('https://'));
      expect(sonarQubeUrlProblem('https://'), contains('host name'));
      expect(
        sonarQubeUrlProblem('https://sonar.example.com/?id=x'),
        contains('SonarQube address only'),
      );
    });

    test('flags http:// as cleartext', () {
      expect(isCleartextUrl('http://sonar.lan:9000'), isTrue);
      expect(isCleartextUrl('https://sonarcloud.io'), isFalse);
    });
  });
}
