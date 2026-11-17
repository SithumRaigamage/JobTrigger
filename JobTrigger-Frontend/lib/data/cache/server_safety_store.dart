import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/safety/server_safety.dart';

part 'server_safety_store.g.dart';

/// Persists the local read-only/protected safety flags (PI-01/02) in
/// `shared_preferences` under a single key. Only opaque ids and URLs are
/// stored — no credentials, no secrets — and the key is registered as
/// user-scoped so it clears on logout.
class ServerSafetyStore {
  static const key = 'server_safety';

  Future<ServerSafety> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Another isolate may have written since.
    final raw = prefs.getString(key);
    if (raw == null) return const ServerSafety();
    try {
      return ServerSafety.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const ServerSafety(); // Corrupt: fail safe to "no flags".
    }
  }

  Future<void> save(ServerSafety safety) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(safety.toJson()));
  }
}

@Riverpod(keepAlive: true)
ServerSafetyStore serverSafetyStore(Ref ref) => ServerSafetyStore();

/// The state screens watch for read-only/protected flags. Follows the
/// synchronous-build pattern from `AppLockNotifier`: state starts empty and
/// is filled from storage in the background, so widgets can `ref.watch` it
/// without handling an `AsyncValue`.
@Riverpod(keepAlive: true)
class ServerSafetyNotifier extends _$ServerSafetyNotifier {
  @override
  ServerSafety build() {
    _load();
    return const ServerSafety();
  }

  Future<void> _load() async {
    final loaded = await ref.read(serverSafetyStoreProvider).load();
    if (!ref.mounted) return;
    state = loaded;
  }

  bool isReadOnly(SafetyTool tool, String credentialId) =>
      state.isReadOnly(tool, credentialId);

  bool isProtected(SafetyTool tool, String jobKey) =>
      state.isProtected(tool, jobKey);

  Future<void> setReadOnly(
    SafetyTool tool,
    String credentialId,
    bool value,
  ) async {
    final next = state.withReadOnly(tool, credentialId, value);
    await _persist(next);
  }

  Future<void> setProtected(
    SafetyTool tool,
    String jobKey,
    bool value,
  ) async {
    final next = state.withProtected(tool, jobKey, value);
    await _persist(next);
  }

  Future<void> _persist(ServerSafety next) async {
    // Optimistic update: the toggle should respond immediately.
    state = next;
    await ref.read(serverSafetyStoreProvider).save(next);
  }
}
