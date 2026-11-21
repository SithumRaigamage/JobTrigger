import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/github_credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/github_credentials_repository.dart';
import 'package:job_trigger/presentation/features/settings/github_credential_edit_bottom_sheet.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// US-GH-CRED-02 "Edit label/org filter" / "Replace the PAT": the token
/// field starts empty; left blank it keeps the stored token, filled in it
/// replaces it.
const _existing = GitHubCredential(
  id: 'gh1',
  label: 'Personal',
  secret: 'fixture-gh-secret',
);

class _Repo implements GitHubCredentialsRepository {
  String? sentSecret;
  String? sentLabel;

  @override
  Future<Result<GitHubCredential, AppFailure>> update(
    String id, {
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  }) async {
    sentLabel = label;
    sentSecret = secret;
    return Ok(GitHubCredential(id: id, label: label, secret: secret));
  }

  @override
  Future<Result<List<GitHubCredential>, AppFailure>> fetchAll() async =>
      const Ok([_existing]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<_Repo> _open(WidgetTester tester) async {
  final repo = _Repo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [gitHubCredentialsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showGitHubCredentialEditBottomSheet(
                context,
                existing: _existing,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
  matching: find.byType(TextField),
);

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  testWidgets('the token field starts empty and blank keeps the stored token', (
    tester,
  ) async {
    final repo = await _open(tester);

    expect(find.text('fixture-gh-secret'), findsNothing);
    await tester.enterText(_field('Label'), 'Personal (renamed)');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.sentLabel, 'Personal (renamed)');
    expect(repo.sentSecret, 'fixture-gh-secret');
  });

  testWidgets('a new token replaces the stored one', (tester) async {
    final repo = await _open(tester);

    await tester.enterText(
      _field('Personal access token'),
      'fixture-new-token',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.sentSecret, 'fixture-new-token');
  });
}
