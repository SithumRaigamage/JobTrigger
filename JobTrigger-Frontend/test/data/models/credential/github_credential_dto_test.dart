import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/credential/github_credential_dto.dart';

void main() {
  group('GitHubCredentialDto', () {
    // Same `_id`-vs-`id` field-name risk as CredentialDto -- Mongo's real
    // key is `_id`.
    test('parses the real _id field name and every other field', () {
      final dto = GitHubCredentialDto.fromJson({
        '_id': 'gh-1',
        'label': 'Personal',
        'token': 'ghp_abc123',
        'defaultOwner': 'octocat',
        'isDefault': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-02T00:00:00.000Z',
      });

      expect(dto.id, 'gh-1');
      expect(dto.label, 'Personal');
      expect(dto.token, 'ghp_abc123');
      expect(dto.defaultOwner, 'octocat');
      expect(dto.isDefault, isTrue);
      expect(dto.createdAt, '2024-01-01T00:00:00.000Z');
      expect(dto.updatedAt, '2024-01-02T00:00:00.000Z');
    });

    test(
      'defaults isDefault to false and leaves optional fields null when absent',
      () {
        final dto = GitHubCredentialDto.fromJson({
          '_id': 'gh-1',
          'label': 'Personal',
          'token': 'ghp_abc123',
        });

        expect(dto.isDefault, isFalse);
        expect(dto.defaultOwner, isNull);
        expect(dto.createdAt, isNull);
        expect(dto.updatedAt, isNull);
      },
    );

    test('toDomain() maps token to the renamed secret field', () {
      final dto = GitHubCredentialDto.fromJson({
        '_id': 'gh-1',
        'label': 'Personal',
        'token': 'ghp_abc123',
        'defaultOwner': 'octocat',
        'isDefault': true,
      });

      final domain = dto.toDomain();
      expect(domain.id, 'gh-1');
      expect(domain.label, 'Personal');
      expect(domain.secret, 'ghp_abc123');
      expect(domain.defaultOwner, 'octocat');
      expect(domain.isDefault, isTrue);
    });
  });
}
