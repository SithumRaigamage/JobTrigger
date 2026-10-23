import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_github_credential_notifier.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/domain/github/github_repository.dart';
import 'package:job_trigger/domain/github/github_workflow.dart';
import 'package:job_trigger/presentation/features/github/github_repo_screen.dart';

/// P14-08: the GitHub repository list as redesigned
/// (`UI-UX/screens/07-home-github-repos`).
class _Credential extends ActiveGitHubCredentialNotifier {
  @override
  GitHubCredential? build() =>
      const GitHubCredential(id: 'g', label: 'acme-bot', secret: 't');
}

class _Repos implements GitHubRepository {
  @override
  Future<Result<List<GitHubRepo>, AppFailure>> fetchRepos() async => const Ok([
    GitHubRepo(
      id: 1,
      name: 'api-gateway',
      owner: 'acme-corp',
      fullName: 'acme-corp/api-gateway',
      private: true,
    ),
    GitHubRepo(
      id: 2,
      name: 'design-tokens',
      owner: 'acme-corp',
      fullName: 'acme-corp/design-tokens',
      defaultBranch: 'trunk',
    ),
  ]);

  @override
  Future<Result<List<GitHubWorkflow>, AppFailure>> fetchWorkflows(
    String owner,
    String repo,
  ) => throw UnimplementedError();
}

void main() {
  testWidgets('lists each repo with its visibility and default branch', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeGitHubCredentialNotifierProvider.overrideWith(_Credential.new),
          gitHubRepositoryProvider.overrideWithValue(_Repos()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const GitHubRepoScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Repositories'), findsOneWidget);
    expect(find.text('acme-bot'), findsOneWidget);
    expect(find.text('acme-corp/api-gateway'), findsOneWidget);
    expect(find.text('Private'), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);
    expect(find.text('trunk'), findsOneWidget);
  });
}
