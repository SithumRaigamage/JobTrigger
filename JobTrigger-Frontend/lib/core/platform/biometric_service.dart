import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_service.g.dart';

/// The result of asking the OS to authenticate the user.
enum AuthOutcome {
  success,

  /// Cancelled, failed, or interrupted: the user can try again.
  failed,

  /// The device has no passcode, PIN, pattern, or biometrics set up, so
  /// there is nothing to authenticate against.
  unavailable,
}

/// A thin wrapper over `local_auth` (US-JX-21), behind a provider so tests
/// can substitute it. Biometrics with the device passcode as fallback.
class BiometricService {
  BiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<AuthOutcome> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        // Retry after an interruption instead of failing.
        persistAcrossBackgrounding: true,
      );
      return ok ? AuthOutcome.success : AuthOutcome.failed;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.noCredentialsSet => AuthOutcome.unavailable,
        _ => AuthOutcome.failed,
      };
    }
  }
}

@Riverpod(keepAlive: true)
BiometricService biometricService(Ref ref) => BiometricService();
