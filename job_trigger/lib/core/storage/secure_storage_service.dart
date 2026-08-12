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
SecureStorageService secureStorage(Ref ref) =>
    SecureStorageService(const FlutterSecureStorage());
