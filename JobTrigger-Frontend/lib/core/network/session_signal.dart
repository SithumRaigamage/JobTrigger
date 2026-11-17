import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_signal.g.dart';

/// Fired by `buildBackendDio`'s `onUnauthorized` callback when a 401 clears
/// the stored session — see `backend_api_client.dart`. `core/network`
/// mustn't import `presentation/features/auth/auth_notifier.dart` directly
/// (would break the layering in `docs/architecture.md`), so this is a
/// dependency-free bridge: `AuthNotifier` listens to it instead (P6-10 —
/// found while testing the 401-mid-session flow that nothing previously
/// caused `AuthNotifier` to ever notice a session had been cleared out from
/// under it, leaving the UI stuck showing "authenticated" until a full
/// app restart).
@Riverpod(keepAlive: true)
class SessionSignal extends _$SessionSignal {
  @override
  int build() => 0;

  void markUnauthorized() => state++;
}
