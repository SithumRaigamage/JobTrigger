import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/credentials/credentials_notifier.dart';
import '../../../data/credentials/github_credentials_notifier.dart';
import '../../../data/credentials/sonarqube_credentials_notifier.dart';
import '../../../domain/auth/auth_state.dart';
import 'auth_notifier.dart';

part 'credentials_resume_reloader.g.dart';

/// US-WEB-17 (owner decision 2026-11-21): when the app comes back to the
/// foreground, reload every tool's saved credentials, so a server added on
/// the website appears without a restart; at most once every [minGap]. The
/// reload also retries a default still waiting to reach the backend and
/// picks up one chosen elsewhere (US-CRED-05, US-WEB-18). Watched by the
/// app root.
@Riverpod(keepAlive: true)
class CredentialsResumeReloader extends _$CredentialsResumeReloader {
  static const minGap = Duration(seconds: 30);

  DateTime? _lastReload;

  @override
  void build() {
    final observer = _ResumeObserver(onResumed);
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
  }

  /// True when it reloaded.
  bool onResumed() {
    if (ref.read(authNotifierProvider).value is! Authenticated) return false;
    final at = now();
    final last = _lastReload;
    if (last != null && at.difference(last) < minGap) return false;
    _lastReload = at;
    ref
      ..invalidate(credentialsNotifierProvider)
      ..invalidate(gitHubCredentialsNotifierProvider)
      ..invalidate(sonarQubeCredentialsNotifierProvider);
    return true;
  }

  /// The current time; tests override it.
  @protected
  DateTime now() => DateTime.now();
}

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this.onResume);

  final void Function() onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
