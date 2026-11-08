import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/credentials/active_server_notifier.dart';
import '../../../data/credentials/credentials_notifier.dart';

part 'home_server_gate_provider.g.dart';

/// What Home can show before it has a Jenkins server to browse (P19-02).
///
/// `ActiveServerNotifier` is `null` both while the saved servers are still
/// being fetched from the backend and when there are none, so the screen
/// could not tell "not loaded yet" from "no server" and flashed the latter.
sealed class HomeServerGate {
  const HomeServerGate();
}

/// The saved servers are loading, or the active one is about to be chosen.
class HomeServerLoading extends HomeServerGate {
  const HomeServerLoading();
}

/// The saved servers could not be loaded; [error] is an `AppFailure`.
class HomeServerFailed extends HomeServerGate {
  const HomeServerFailed(this.error);

  final Object error;
}

/// The saved servers loaded and there are none.
class HomeServerNone extends HomeServerGate {
  const HomeServerNone();
}

@riverpod
HomeServerGate homeServerGate(Ref ref) {
  // Only meaningful while no server is active (Home reads it then). With
  // one active, don't watch the list, so reloading it rebuilds nothing.
  if (ref.watch(activeServerNotifierProvider) != null) {
    return const HomeServerLoading();
  }
  final servers = ref.watch(credentialsNotifierProvider);
  // Checked first: while Riverpod retries a failed load the value is
  // loading yet still carries the error, which the user should see now.
  if (servers.hasError) return HomeServerFailed(servers.error!);
  return switch (servers) {
    AsyncData(:final value) when value.isEmpty => const HomeServerNone(),
    // Loading, or loaded but `ActiveServerNotifier` hasn't picked one yet.
    _ => const HomeServerLoading(),
  };
}
