import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/presentation/features/settings/server_edit_bottom_sheet.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// US-CRED-03 "Password field starts empty" (owner decision 2026-11-21).
const _existing = JenkinsServer(
  id: 'a',
  serverName: 'Acme production',
  jenkinsURL: 'https://ci.acme.dev',
  username: 'sam',
  secret: 'fixture-stored-secret',
);

class _Repo implements CredentialsRepository {
  String? sentSecret;

  @override
  Future<Result<JenkinsServer, AppFailure>> update(
    String id, {
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) async {
    sentSecret = secret;
    return Ok(
      JenkinsServer(
        id: id,
        serverName: serverName,
        jenkinsURL: jenkinsURL,
        username: username,
        secret: secret,
      ),
    );
  }

  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      const Ok([_existing]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<_Repo> _open(WidgetTester tester) async {
  final repo = _Repo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  showServerEditBottomSheet(context, existing: _existing),
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

Finder _tokenField() => find.descendant(
  of: find
      .ancestor(of: find.text('API token'), matching: find.byType(Column))
      .first,
  matching: find.byType(TextField),
);

void main() {
  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  testWidgets('the token field starts empty and says blank keeps it', (
    tester,
  ) async {
    await _open(tester);

    expect(tester.widget<TextField>(_tokenField()).controller!.text, isEmpty);
    expect(find.text('Leave blank to keep current.'), findsOneWidget);
    expect(find.text('fixture-stored-secret'), findsNothing);
  });

  testWidgets('saving with it blank keeps the stored secret', (tester) async {
    final repo = await _open(tester);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.sentSecret, 'fixture-stored-secret');
  });

  testWidgets('a new token replaces the stored one', (tester) async {
    final repo = await _open(tester);

    await tester.enterText(_tokenField(), 'fixture-new-token');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.sentSecret, 'fixture-new-token');
  });
}
