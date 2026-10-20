import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/auth/user_dto.dart';

void main() {
  group('UserDto', () {
    // The backend responds with Mongo's `_id` key, not a bare `id` -- this
    // fixture exists specifically to catch a regression there, same
    // reasoning as `github_repo_dto_test.dart`'s snake_case check.
    test('parses the real _id field name', () {
      final dto = UserDto.fromJson({
        '_id': 'user-1',
        'email': 'jane@example.com',
      });

      expect(dto.id, 'user-1');
      expect(dto.email, 'jane@example.com');
    });

    test('toDomain() carries id and email through unchanged', () {
      final dto = UserDto.fromJson({
        '_id': 'user-1',
        'email': 'jane@example.com',
      });

      final domain = dto.toDomain();
      expect(domain.id, 'user-1');
      expect(domain.email, 'jane@example.com');
    });
  });

  group('AuthResponseDto', () {
    test('parses the token + nested user envelope', () {
      final dto = AuthResponseDto.fromJson({
        'token': 'jwt-abc',
        'user': {'_id': 'user-1', 'email': 'jane@example.com'},
      });

      expect(dto.token, 'jwt-abc');
      expect(dto.user.id, 'user-1');
      expect(dto.user.email, 'jane@example.com');
    });
  });
}
