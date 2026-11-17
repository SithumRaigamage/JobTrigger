import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/platform/home_widget_bridge.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../data/demo/demo_mode_notifier.dart';
import '../../../domain/auth/auth_state.dart';
import '../../../domain/widget/widget_snapshot.dart';
import '../app_lock/app_lock_notifier.dart';
import '../auth/auth_notifier.dart';
import '../sonarqube/sonarqube_pins_notifier.dart';
import '../sonarqube/sonarqube_summaries_notifier.dart';
import '../subscription/plan_gate.dart';

part 'sonarqube_widget_sync.g.dart';

/// `US-SQ-WIDGET-01`: keeps the pinned-projects widget's snapshot in step
/// with the pins and their gate verdicts, the way [homeWidgetSync] does for
/// Jenkins jobs. The widget renders the snapshot and never calls SonarQube,
/// and holds no credential. Watched from `main.dart`.
@Riverpod(keepAlive: true)
void sonarQubeWidgetSync(Ref ref) {
  final signedIn = ref.watch(
    authNotifierProvider.select((auth) => auth.value is Authenticated),
  );
  if (!signedIn) return;
  // Sample data must never reach the real home-screen widget (PE-14).
  if (ref.watch(demoModeNotifierProvider)) return;
  // No SonarQube credential: leave whatever is on the widget alone rather than
  // wipe it on a transient state; logout clears it.
  if (ref.watch(activeSonarQubeCredentialNotifierProvider) == null) return;
  final bridge = ref.read(homeWidgetBridgeProvider);
  // The plan decides, as it does for pinned jobs (P20-25).
  if (ref.watch(planGateProvider).homeWidget != null) {
    bridge.writeSonarQube(
      WidgetSnapshot(
        jobs: const [],
        updatedAt: DateTime.now(),
        upgradeRequired: true,
      ),
    );
    return;
  }
  // AUD-54: names stay off the home screen while the app lock is on.
  final lock = ref.watch(
    appLockNotifierProvider.select(
      (state) => (loaded: state.loaded, enabled: state.settings.enabled),
    ),
  );
  if (!lock.loaded) return;

  final pins = ref
      .watch(sonarQubePinsNotifierProvider)
      .take(WidgetSnapshot.maxJobs)
      .toList();
  final summaries = ref.watch(sonarQubeSummariesNotifierProvider);
  final missing = [
    for (final pin in pins)
      if (!summaries.byKey.containsKey(pin.key)) pin.key,
  ];
  if (missing.isNotEmpty) {
    // Fetch what the cards have not already loaded; this provider rebuilds
    // when they arrive and writes the snapshot then.
    Future.microtask(
      () =>
          ref.read(sonarQubeSummariesNotifierProvider.notifier).ensure(missing),
    );
    // Nothing known yet (a cold start): keep the last snapshot.
    if (missing.length == pins.length && pins.isNotEmpty) return;
  }
  bridge.writeSonarQube(
    buildSonarQubeWidgetSnapshot(
      [
        for (final pin in pins)
          (
            key: pin.key,
            name: pin.name,
            gate: summaries.byKey[pin.key]?.gate.name,
          ),
      ],
      now: DateTime.now(),
      hideNames: lock.enabled,
    ),
  );
}
