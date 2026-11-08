import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/github/github_job.dart';
import 'package:job_trigger/domain/github/github_status.dart';

void main() {
  test('a step or job uses the same status + conclusion rules as a run', () {
    const step = GitHubStep(
      number: 1,
      name: 'Build',
      status: 'completed',
      conclusion: 'failure',
    );
    expect(step.outcome, GitHubRunOutcome.failure);
    expect(step.label, 'Failed');

    const job = GitHubJob(
      id: 1,
      name: 'test',
      status: 'in_progress',
      conclusion: null,
      steps: [step],
    );
    expect(job.outcome, GitHubRunOutcome.running);
    expect(job.isCompleted, isFalse);
  });

  test('skipped steps are neutral, not failures', () {
    expect(githubOutcome('completed', 'skipped'), GitHubRunOutcome.neutral);
    expect(githubLabel('completed', 'skipped'), 'Skipped');
  });

  test('a queued step that has not started reads as queued', () {
    expect(githubOutcome('pending', null), GitHubRunOutcome.queued);
  });
}
