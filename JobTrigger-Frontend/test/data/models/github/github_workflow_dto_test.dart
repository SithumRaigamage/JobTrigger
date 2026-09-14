import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/github/github_workflow_dto.dart';

void main() {
  group('GitHubWorkflowDto (US-GH-REPO-02)', () {
    test('parses id/name/path/state', () {
      final dto = GitHubWorkflowDto.fromJson({
        'id': 42,
        'name': 'CI',
        'path': '.github/workflows/ci.yml',
        'state': 'active',
      });

      expect(dto.id, 42);
      expect(dto.name, 'CI');
      expect(dto.path, '.github/workflows/ci.yml');
      expect(dto.state, 'active');
    });

    test('toDomain().isActive is true only for state == active', () {
      final active = GitHubWorkflowDto.fromJson({
        'id': 1,
        'name': 'CI',
        'path': 'x',
        'state': 'active',
      }).toDomain();
      final disabled = GitHubWorkflowDto.fromJson({
        'id': 2,
        'name': 'Old',
        'path': 'y',
        'state': 'disabled_manually',
      }).toDomain();

      expect(active.isActive, isTrue);
      expect(disabled.isActive, isFalse);
    });
  });
}
