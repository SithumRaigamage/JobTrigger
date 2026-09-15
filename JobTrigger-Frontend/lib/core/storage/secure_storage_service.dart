import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_service.g.dart';

/// Thin typed wrapper over `flutter_secure_storage`. Per CLAUDE.md §7, the
/// JWT never touches `shared_preferences` — this is the only place it's
/// persisted.
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clear() => _storage.deleteAll();
}

@riverpod
SecureStorageService secureStorage(Ref ref) => SecureStorageService(
  const FlutterSecureStorage(
    // macOS's "data protection keychain" (the default) resolves its
    // keychain-access-group from the app's code-signing Team ID —
    // without a real Apple Developer certificate (this is a local-dev-only
    // macOS target, not a distribution one; see the entitlements files'
    // comments), that fails with errSecMissingEntitlement (-34018) even
    // with App Sandbox off. The legacy (non-data-protection) keychain API
    // doesn't need a Team ID. iOS/Android are unaffected — this option is
    // macOS-only.
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  ),
);
