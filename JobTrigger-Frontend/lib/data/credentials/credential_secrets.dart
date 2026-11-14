import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/storage/secure_storage_service.dart';

/// A secret fetched from `GET <credentials path>/:id/secret` (E4, PE-32).
class StoredSecret {
  const StoredSecret({this.primary, this.extra, this.version});

  /// The password (Jenkins) or token (GitHub, SonarQube).
  final String? primary;

  /// Jenkins' build-trigger token.
  final String? extra;

  /// The credential's `updatedAt` when the secret was fetched: it changes
  /// whenever the credential is saved, so a stored copy with an older
  /// version is out of date.
  final String? version;
}

/// E4 (PE-34): the app's copy of the secrets the backend no longer puts in
/// its list responses. A secret is fetched from the owner-only endpoint the
/// first time it is needed, then kept in `flutter_secure_storage` only, and
/// fetched again when the credential was saved since. Logout clears the
/// whole store ([SecureStorageService.clear]), and a deleted credential's
/// entry is removed here.
///
/// Each repository calls this from its own data layer, so screens and
/// notifiers still see a credential with its secret, as before.
class CredentialSecrets {
  CredentialSecrets(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  static String _key(String tool, String id) => 'credential_secret_${tool}_$id';

  /// The secret for [id], from storage when its version still matches
  /// [listedVersion] (the `updatedAt` of the list entry), else from the
  /// endpoint at [path]. Null when it can't be had: unreadable on the
  /// server, or a failed request. A failure is not an error here, because
  /// one credential's secret must not take down the whole list; the
  /// credential just stays unusable until the next load.
  Future<StoredSecret?> resolve({
    required String tool,
    required String path,
    required String id,
    required String? listedVersion,
    required String primaryField,
    String? extraField,
  }) async {
    final cached = await _read(tool, id);
    if (cached != null && _sameVersion(cached.version, listedVersion)) {
      return cached;
    }
    final fetched = await guardRequest(() async {
      final response = await _dio.get<Map<String, dynamic>>('$path/$id/secret');
      final data = response.data!;
      if (data['needsReentry'] == true || data[primaryField] is! String) {
        return null;
      }
      return StoredSecret(
        primary: data[primaryField] as String,
        extra: extraField == null ? null : data[extraField] as String?,
        version: data['version'] as String?,
      );
    });
    final secret = switch (fetched) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (secret != null) await _write(tool, id, secret);
    return secret;
  }

  /// Keeps what the user just typed, so saving a credential doesn't need a
  /// fetch. [version] is the saved credential's `updatedAt`.
  Future<void> remember(
    String tool,
    String id, {
    required String primary,
    String? extra,
    String? version,
  }) => _write(
    tool,
    id,
    StoredSecret(primary: primary, extra: extra, version: version),
  );

  Future<void> forget(String tool, String id) =>
      _storage.deleteValue(_key(tool, id));

  Future<StoredSecret?> _read(String tool, String id) async {
    final raw = await _storage.readValue(_key(tool, id));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return StoredSecret(
        primary: map['primary'] as String?,
        extra: map['extra'] as String?,
        version: map['version'] as String?,
      );
    } on Object {
      return null; // Unreadable is just absent: fetch it again.
    }
  }

  Future<void> _write(String tool, String id, StoredSecret secret) =>
      _storage.writeValue(
        _key(tool, id),
        jsonEncode({
          'primary': secret.primary,
          'extra': secret.extra,
          'version': secret.version,
        }),
      );

  /// Both versions are ISO timestamps of one instant; compare them as
  /// instants, not strings. Without a listed version there is nothing to
  /// compare, so a stored copy is trusted.
  static bool _sameVersion(String? stored, String? listed) {
    if (listed == null) return true;
    final a = stored == null ? null : DateTime.tryParse(stored);
    final b = DateTime.tryParse(listed);
    if (a == null || b == null) return stored == listed;
    return a.isAtSameMomentAs(b);
  }
}
