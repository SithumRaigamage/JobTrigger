import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/platform/home_widget_bridge.dart';
import '../../../domain/auth/auth_state.dart';
import '../../../domain/widget/widget_snapshot.dart';
import '../auth/auth_notifier.dart';
import '../home/pinned_jobs_notifier.dart';

part 'home_widget_sync.g.dart';

/// US-JX-23: keeps the home-screen widget's snapshot in step with the
/// pinned jobs. Watching each pin's status keeps it fetched while the app
/// runs, and every refresh rewrites the snapshot. Watched from `main.dart`.
@Riverpod(keepAlive: true)
void homeWidgetSync(Ref ref) {
  // Only once signed in: watching the pins builds the active server, which
  // must not rehydrate (and stay stale) before login. Logout clears the
  // snapshot itself (AuthNotifier.logout).
  final signedIn = ref.watch(
    authNotifierProvider.select((auth) => auth.value is Authenticated),
  );
  if (!signedIn) return;
  final pins = ref.watch(pinnedJobsNotifierProvider);
  final statuses = [
    for (final pin in pins.take(WidgetSnapshot.maxJobs))
      ref.watch(pinnedJobStatusProvider(pin.url)),
  ];
  // Nothing known yet (a cold start): keep the last snapshot rather than
  // replace it with rows of "Unknown".
  if (pins.isNotEmpty && statuses.every((status) => !status.hasValue)) {
    return;
  }
  final snapshot = buildWidgetSnapshot([
    for (final (i, pin) in pins.take(WidgetSnapshot.maxJobs).indexed)
      (label: pin.label, url: pin.url, job: statuses[i].value),
  ], now: DateTime.now());
  ref.read(homeWidgetBridgeProvider).write(snapshot);
}
