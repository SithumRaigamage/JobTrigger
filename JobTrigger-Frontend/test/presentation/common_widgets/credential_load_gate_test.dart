import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_github_credential_notifier.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/credentials/github_credentials_notifier.dart';
import 'package:job_trigger/data/credentials/sonarqube_credentials_notifier.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/presentation/common_widgets/credential_load_gate.dart';
import 'package:job_trigger/presentation/features/github/github_repo_screen.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_project_screen.dart';

/// "No credential" must mean there is none, not that the saved list has not
/// arrived yet: the first-open flash the owner saw (same fix as P19-02).
class _NoActiveSonar extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => null;
}

class _NoActiveGitHub extends ActiveGitHubCredentialNotifier {
  @override
  GitHubCredential? build() => null;
}

/// A saved-list notifier whose next load is whatever [next] returns, so a
/// test can make it slow, empty, failing, or fixed on retry.
class _SonarList extends SonarQubeCredentialsNotifier {
  _SonarList(this.next);

  final Future<List<SonarQubeCredential>> Function() next;

  @override
  Future<List<SonarQubeCredential>> build() => next();
}

class _GitHubList extends GitHubCredentialsNotifier {
  _GitHubList(this.next);

  final Future<List<GitHubCredential>> Function() next;

  @override
  Future<List<GitHubCredential>> build() => next();
}

const _sonarCredential = SonarQubeCredential(
  id: 'c',
  label: 'Local',
  baseUrl: 'http://sonar.test',
  secret: 't',
);

Widget _app(List<Override> overrides, Widget home) => ProviderScope(
  retry: (retryCount, error) => null,
  overrides: overrides,
  child: MaterialApp(theme: AppTheme.dark(), home: home),
);

void main() {
  group('CredentialLoadGate itself', () {
    Widget gate(AsyncValue<List<Object?>> saved, VoidCallback onRetry) =>
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CredentialLoadGate(
                saved: saved,
                none: const Text('NONE'),
                onRetry: onRetry,
              ),
            ),
          ),
        );

    testWidgets('loading is a spinner, never "none"', (tester) async {
      await tester.pumpWidget(gate(const AsyncLoading(), () {}));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('NONE'), findsNothing);
    });

    testWidgets('an empty list is "none"', (tester) async {
      await tester.pumpWidget(gate(const AsyncData(<Object?>[]), () {}));
      expect(find.text('NONE'), findsOneWidget);
    });

    testWidgets('saved credentials but none active yet is a spinner', (
      tester,
    ) async {
      await tester.pumpWidget(gate(const AsyncData(<Object?>['x']), () {}));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('NONE'), findsNothing);
    });

    testWidgets('a failed load shows the error with a working retry', (
      tester,
    ) async {
      var retried = 0;
      await tester.pumpWidget(
        gate(
          const AsyncError<List<Object?>>(NetworkFailure(), StackTrace.empty),
          () => retried++,
        ),
      );
      expect(find.textContaining("Can't reach the server"), findsOneWidget);
      await tester.tap(find.text('Retry Connection'));
      expect(retried, 1);
    });
  });

  group('SonarQube Home on first open', () {
    List<Override> base(Future<List<SonarQubeCredential>> Function() next) => [
      activeSonarQubeCredentialNotifierProvider.overrideWith(
        _NoActiveSonar.new,
      ),
      sonarQubeCredentialsNotifierProvider.overrideWith(() => _SonarList(next)),
    ];

    testWidgets('does not say "no credential" while the list loads', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          base(
            () => Future<List<SonarQubeCredential>>.delayed(
              const Duration(seconds: 30),
              () => const [],
            ),
          ),
          const SonarQubeProjectScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No SonarQube Credential'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets('says so once the list is loaded and empty', (tester) async {
      await tester.pumpWidget(
        _app(base(() async => const []), const SonarQubeProjectScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('No SonarQube Credential'), findsOneWidget);
    });

    testWidgets('a failed load shows the error, and Retry recovers', (
      tester,
    ) async {
      var attempts = 0;
      await tester.pumpWidget(
        _app(
          base(() async {
            attempts++;
            if (attempts == 1) throw const NetworkFailure();
            return const [];
          }),
          const SonarQubeProjectScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining("Can't reach the server"), findsOneWidget);
      expect(find.text('No SonarQube Credential'), findsNothing);

      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();

      expect(find.text('No SonarQube Credential'), findsOneWidget);
    });

    testWidgets('saved credentials that are not active yet stay a spinner', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          base(() async => const [_sonarCredential]),
          const SonarQubeProjectScreen(),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No SonarQube Credential'), findsNothing);
    });
  });

  group('GitHub Home on first open (same flash, same fix)', () {
    List<Override> base(Future<List<GitHubCredential>> Function() next) => [
      activeGitHubCredentialNotifierProvider.overrideWith(_NoActiveGitHub.new),
      gitHubCredentialsNotifierProvider.overrideWith(() => _GitHubList(next)),
    ];

    testWidgets('does not say "no credential" while the list loads', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          base(
            () => Future<List<GitHubCredential>>.delayed(
              const Duration(seconds: 30),
              () => const [],
            ),
          ),
          const GitHubRepoScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No GitHub Credential'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets('says so once the list is loaded and empty', (tester) async {
      await tester.pumpWidget(
        _app(base(() async => const []), const GitHubRepoScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('No GitHub Credential'), findsOneWidget);
    });

    testWidgets('a failed load shows the error, and Retry recovers', (
      tester,
    ) async {
      var attempts = 0;
      await tester.pumpWidget(
        _app(
          base(() async {
            attempts++;
            if (attempts == 1) throw const NetworkFailure();
            return const [];
          }),
          const GitHubRepoScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining("Can't reach the server"), findsOneWidget);

      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();

      expect(find.text('No GitHub Credential'), findsOneWidget);
    });
  });
}
