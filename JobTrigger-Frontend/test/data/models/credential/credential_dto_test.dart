import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/credential/credential_dto.dart';

void main() {
  group('CredentialDto', () {
    // Mongo's real id key is `_id` -- this fixture exists specifically to
    // catch a regression to a bare `id` field name, which would silently
    // fail to parse the id (it's `required`, so this would throw instead
    // of quietly defaulting -- but it's still the field-name risk worth
    // pinning down explicitly, same reasoning as `github_repo_dto_test.dart`).
    test('parses the real _id field name and every other field', () {
      final dto = CredentialDto.fromJson({
        '_id': 'cred-1',
        'serverName': 'Prod Jenkins',
        'jenkinsURL': 'https://jenkins.example.com',
        'username': 'admin',
        'password': 's3cret',
        'paramToken': 'tok-123',
        'isDefault': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-02T00:00:00.000Z',
      });

      expect(dto.id, 'cred-1');
      expect(dto.serverName, 'Prod Jenkins');
      expect(dto.jenkinsURL, 'https://jenkins.example.com');
      expect(dto.username, 'admin');
      expect(dto.password, 's3cret');
      expect(dto.paramToken, 'tok-123');
      expect(dto.isDefault, isTrue);
      expect(dto.createdAt, '2024-01-01T00:00:00.000Z');
      expect(dto.updatedAt, '2024-01-02T00:00:00.000Z');
    });

    test(
      'defaults isDefault to false and leaves optional fields null when absent',
      () {
        final dto = CredentialDto.fromJson({
          '_id': 'cred-1',
          'serverName': 'Prod Jenkins',
          'jenkinsURL': 'https://jenkins.example.com',
          'username': 'admin',
          'password': 's3cret',
        });

        expect(dto.isDefault, isFalse);
        expect(dto.paramToken, isNull);
        expect(dto.createdAt, isNull);
        expect(dto.updatedAt, isNull);
      },
    );

    test('toDomain() maps password to the renamed secret field', () {
      final dto = CredentialDto.fromJson({
        '_id': 'cred-1',
        'serverName': 'Prod Jenkins',
        'jenkinsURL': 'https://jenkins.example.com',
        'username': 'admin',
        'password': 's3cret',
        'paramToken': 'tok-123',
        'isDefault': true,
      });

      final domain = dto.toDomain();
      expect(domain.id, 'cred-1');
      expect(domain.serverName, 'Prod Jenkins');
      expect(domain.jenkinsURL, 'https://jenkins.example.com');
      expect(domain.username, 'admin');
      expect(domain.secret, 's3cret');
      expect(domain.paramToken, 'tok-123');
      expect(domain.isDefault, isTrue);
    });
  });
}
