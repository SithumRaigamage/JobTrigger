import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/credentials/credentials_notifier.dart';
import 'package:job_trigger/data/credentials/github_credentials_notifier.dart';
import 'package:job_trigger/data/credentials/sonarqube_credentials_notifier.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/credential/github_credential.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/auth/credentials_resume_reloader.dart';

/// US-WEB-17 (owner decision 2026-11-21): resuming reloads every tool's
/// credentials, at most once every 30 seconds, and only when signed in.
var _loads = <String, int>{};

class _Jenkins extends CredentialsNotifier {
  @override
  Future<List<JenkinsServer>> build() async {
    _loads['jenkins'] = (_loads['jenkins'] ?? 0) + 1;
    return const [];
  }
}

class _GitHub extends GitHubCredentialsNotifier {
  @override
  Future<List<GitHubCredential>> build() async {
    _loads['github'] = (_loads['github'] ?? 0) + 1;
    return const [];
  }
}

class _Sonar extends SonarQubeCredentialsNotifier {
  @override
  Future<List<SonarQubeCredential>> build() async {
    _loads['sonarqube'] = (_loads['sonarqube'] ?? 0) + 1;
    return const [];
  }
}

class _Auth extends AuthNotifier {
  _Auth(this.signedIn);

  final bool signedIn;

  @override
  Future<AuthState> build() async => signedIn
      ? const Authenticated(User(id: 'u', email: 'sam@acme.dev'))
      : const Unauthenticated();
}

class _Clocked extends CredentialsResumeReloader {
  DateTime time = DateTime(2026, 11, 21, 12);

  @override
  DateTime now() => time;
}

Future<(ProviderContainer, _Clocked)> _setUp({bool signedIn = true}) async {
  _loads = {};
  late _Clocked reloader;
  final c = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(() => _Auth(signedIn)),
      credentialsNotifierProvider.overrideWith(_Jenkins.new),
      gitHubCredentialsNotifierProvider.overrideWith(_GitHub.new),
      sonarQubeCredentialsNotifierProvider.overrideWith(_Sonar.new),
      credentialsResumeReloaderProvider.overrideWith(
        () => reloader = _Clocked(),
      ),
    ],
  );
  addTearDown(c.dispose);
  c.listen(credentialsNotifierProvider, (_, _) {});
  c.listen(gitHubCredentialsNotifierProvider, (_, _) {});
  c.listen(sonarQubeCredentialsNotifierProvider, (_, _) {});
  c.listen(authNotifierProvider, (_, _) {});
  await c.read(authNotifierProvider.future);
  c.read(credentialsResumeReloaderProvider);
  await Future<void>.delayed(Duration.zero);
  return (c, reloader);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resuming reloads Jenkins, GitHub and SonarQube credentials', () async {
    final (_, reloader) = await _setUp();
    expect(_loads, {'jenkins': 1, 'github': 1, 'sonarqube': 1});

    expect(reloader.onResumed(), isTrue);
    await _settle();

    expect(_loads, {'jenkins': 2, 'github': 2, 'sonarqube': 2});
  });

  test(
    'a second resume within 30 seconds does nothing; after, it reloads',
    () async {
      final (_, reloader) = await _setUp();
      reloader.onResumed();
      await _settle();

      reloader.time = reloader.time.add(const Duration(seconds: 29));
      expect(reloader.onResumed(), isFalse);
      await _settle();
      expect(_loads['jenkins'], 2);

      reloader.time = reloader.time.add(const Duration(seconds: 2));
      expect(reloader.onResumed(), isTrue);
      await _settle();
      expect(_loads['jenkins'], 3);
    },
  );

  test('signed out, resuming reloads nothing', () async {
    final (_, reloader) = await _setUp(signedIn: false);

    expect(reloader.onResumed(), isFalse);
    await _settle();
    expect(_loads['jenkins'], 1);
  });
}
