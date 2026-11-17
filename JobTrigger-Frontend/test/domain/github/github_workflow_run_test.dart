import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/github/github_workflow_run.dart';

GitHubWorkflowRun _run(String status, [String? conclusion]) =>
    GitHubWorkflowRun(
      id: 1,
      runNumber: 1,
      title: 't',
      event: 'push',
      status: status,
      conclusion: conclusion,
      branch: 'main',
      createdAt: null,
      htmlUrl: '',
    );

void main() {
  group('GitHubWorkflowRun status + conclusion (US-GH-RUN-01)', () {
    test('a run that has not completed ignores any conclusion', () {
      expect(_run('in_progress').outcome, GitHubRunOutcome.running);
      expect(_run('in_progress').label, 'In progress');
      for (final s in ['queued', 'waiting', 'requested', 'pending']) {
        expect(_run(s).outcome, GitHubRunOutcome.queued, reason: s);
        expect(_run(s).isActive, isTrue);
      }
    });

    test('a completed run maps its conclusion', () {
      expect(_run('completed', 'success').outcome, GitHubRunOutcome.success);
      for (final c in ['failure', 'timed_out', 'startup_failure']) {
        expect(_run('completed', c).outcome, GitHubRunOutcome.failure);
      }
      expect(
        _run('completed', 'action_required').outcome,
        GitHubRunOutcome.attention,
      );
      for (final c in ['cancelled', 'skipped', 'neutral', 'stale']) {
        expect(_run('completed', c).outcome, GitHubRunOutcome.neutral);
      }
      expect(_run('completed', 'success').isCompleted, isTrue);
      expect(_run('completed', 'success').isActive, isFalse);
    });

    test('labels are human copy, including values GitHub adds later', () {
      expect(_run('completed', 'failure').label, 'Failed');
      expect(_run('completed', 'timed_out').label, 'Timed out');
      expect(_run('completed').label, 'Completed');
      expect(_run('completed', 'some_new_value').label, 'Some new value');
      expect(_run('brand_new_status').label, 'Brand new status');
      expect(_run('brand_new_status').outcome, GitHubRunOutcome.queued);
    });
  });
}
