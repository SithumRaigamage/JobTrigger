import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../data/credentials/sonarqube_credentials_notifier.dart';
import '../../common_widgets/credential_load_gate.dart';
import '../../common_widgets/no_active_sonarqube_credential_view.dart';

/// A full screen for a SonarQube tab that has no active credential yet: a
/// spinner while the saved list loads, the error with a retry if it failed,
/// and "no credential" only when there really is none.
class SonarQubeCredentialGate extends ConsumerWidget {
  const SonarQubeCredentialGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: SafeArea(
      child: Center(
        child: CredentialLoadGate(
          saved: ref.watch(sonarQubeCredentialsNotifierProvider),
          none: const NoActiveSonarQubeCredentialView(),
          onRetry: () {
            ref.invalidate(sonarQubeCredentialsNotifierProvider);
            ref.invalidate(activeSonarQubeCredentialNotifierProvider);
          },
        ),
      ),
    ),
  );
}
