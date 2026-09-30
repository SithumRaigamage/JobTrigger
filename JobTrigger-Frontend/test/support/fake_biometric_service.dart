import 'package:job_trigger/core/platform/biometric_service.dart';

/// Answers every prompt with [outcome] and records the reasons asked for.
class FakeBiometricService implements BiometricService {
  FakeBiometricService([this.outcome = AuthOutcome.success]);

  AuthOutcome outcome;
  final reasons = <String>[];

  @override
  Future<AuthOutcome> authenticate(String reason) async {
    reasons.add(reason);
    return outcome;
  }
}
