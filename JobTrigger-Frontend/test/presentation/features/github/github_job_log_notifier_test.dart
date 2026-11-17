import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/presentation/features/github/github_job_log_notifier.dart';

import '../../../support/fake_github_repository.dart';

ProviderContainer _container(FakeGitHubRepository repo) {
  final c = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [gitHubRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('keeps the raw text and decodes ANSI into lines', () async {
    final repo = FakeGitHubRepository()
      ..logResult = const Ok('\x1B[32mok\x1B[0m\nplain');
    final c = _container(repo);

    final log = await c.read(gitHubJobLogNotifierProvider('o', 'r', 1).future);

    expect(log.text, '\x1B[32mok\x1B[0m\nplain');
    expect(log.lines.map((l) => l.text), ['ok', 'plain']);
  });

  test('refresh() fetches again; failures surface as the AppFailure', () async {
    final repo = FakeGitHubRepository()..logResult = const Ok('one\n');
    final c = _container(repo);
    c.listen(gitHubJobLogNotifierProvider('o', 'r', 1), (_, _) {});
    await c.read(gitHubJobLogNotifierProvider('o', 'r', 1).future);

    repo.logResult = const Err(NetworkFailure());
    await c.read(gitHubJobLogNotifierProvider('o', 'r', 1).notifier).refresh();

    await expectLater(
      c.read(gitHubJobLogNotifierProvider('o', 'r', 1).future),
      throwsA(isA<NetworkFailure>()),
    );
    expect(repo.fetchJobLogCalls, 2);
  });
}
