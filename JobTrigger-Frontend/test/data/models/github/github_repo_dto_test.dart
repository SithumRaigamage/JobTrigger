import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/github/github_repo_dto.dart';

void main() {
  group('GitHubRepoDto (US-GH-REPO-01)', () {
    // GitHub's real JSON is snake_case (full_name, default_branch) --
    // this fixture exists specifically to catch a regression to bare
    // camelCase field names, which would silently parse to defaults
    // instead of throwing (owner is required so that part would fail
    // loudly, but fullName/defaultBranch would not).
    test('parses the real snake_case field names', () {
      final dto = GitHubRepoDto.fromJson({
        'id': 123,
        'name': 'my-repo',
        'full_name': 'octocat/my-repo',
        'owner': {'login': 'octocat'},
        'private': true,
        'default_branch': 'develop',
      });

      expect(dto.id, 123);
      expect(dto.name, 'my-repo');
      expect(dto.fullName, 'octocat/my-repo');
      expect(dto.owner.login, 'octocat');
      expect(dto.private, isTrue);
      expect(dto.defaultBranch, 'develop');
    });

    test('defaults private to false and defaultBranch to main when absent', () {
      final dto = GitHubRepoDto.fromJson({
        'id': 123,
        'name': 'my-repo',
        'full_name': 'octocat/my-repo',
        'owner': {'login': 'octocat'},
      });

      expect(dto.private, isFalse);
      expect(dto.defaultBranch, 'main');
    });

    test('toDomain() maps owner.login to the flat owner field', () {
      final dto = GitHubRepoDto.fromJson({
        'id': 123,
        'name': 'my-repo',
        'full_name': 'octocat/my-repo',
        'owner': {'login': 'octocat'},
      });

      final domain = dto.toDomain();
      expect(domain.owner, 'octocat');
      expect(domain.fullName, 'octocat/my-repo');
    });
  });
}
