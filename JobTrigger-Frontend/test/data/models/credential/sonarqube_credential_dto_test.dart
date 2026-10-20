import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/credential/sonarqube_credential_dto.dart';

void main() {
  group('SonarQubeCredentialDto', () {
    // Same `_id`-vs-`id` field-name risk as CredentialDto/GitHubCredentialDto
    // -- Mongo's real key is `_id`.
    test('parses the real _id field name and every other field', () {
      final dto = SonarQubeCredentialDto.fromJson({
        '_id': 'sq-1',
        'label': 'Personal',
        'baseUrl': 'https://sonarcloud.io',
        'token': 'squ_abc123',
        'defaultOrganization': 'octocat-org',
        'isDefault': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-02T00:00:00.000Z',
      });

      expect(dto.id, 'sq-1');
      expect(dto.label, 'Personal');
      expect(dto.baseUrl, 'https://sonarcloud.io');
      expect(dto.token, 'squ_abc123');
      expect(dto.defaultOrganization, 'octocat-org');
      expect(dto.isDefault, isTrue);
      expect(dto.createdAt, '2024-01-01T00:00:00.000Z');
      expect(dto.updatedAt, '2024-01-02T00:00:00.000Z');
    });

    test(
      'defaults isDefault to false and leaves optional fields null when absent',
      () {
        final dto = SonarQubeCredentialDto.fromJson({
          '_id': 'sq-1',
          'label': 'Personal',
          'baseUrl': 'https://sonarcloud.io',
          'token': 'squ_abc123',
        });

        expect(dto.isDefault, isFalse);
        expect(dto.defaultOrganization, isNull);
        expect(dto.createdAt, isNull);
        expect(dto.updatedAt, isNull);
      },
    );

    test('toDomain() maps token to the renamed secret field', () {
      final dto = SonarQubeCredentialDto.fromJson({
        '_id': 'sq-1',
        'label': 'Personal',
        'baseUrl': 'https://sonarcloud.io',
        'token': 'squ_abc123',
        'defaultOrganization': 'octocat-org',
        'isDefault': true,
      });

      final domain = dto.toDomain();
      expect(domain.id, 'sq-1');
      expect(domain.label, 'Personal');
      expect(domain.baseUrl, 'https://sonarcloud.io');
      expect(domain.secret, 'squ_abc123');
      expect(domain.defaultOrganization, 'octocat-org');
      expect(domain.isDefault, isTrue);
    });
  });
}
