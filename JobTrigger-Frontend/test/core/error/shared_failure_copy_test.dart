import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';

/// Earlier work must keep working: the SonarQube fixes added failure types
/// of their own, so the wording that Jenkins and GitHub Actions show for the
/// shared failures must be exactly what it was.
void main() {
  test('shared failures keep their wording', () {
    expect(
      const PermissionFailure().message,
      "You don't have permission to do this on this server.",
    );
    expect(
      const NotFoundFailure().message,
      "That couldn't be found — it may have been removed.",
    );
    expect(
      const AuthFailure().message,
      'Your credentials were rejected. Please check them and try again.',
    );
    expect(
      const RateLimitFailure().message,
      "GitHub's rate limit was reached. Please wait a bit and try again.",
    );
  });

  test('the SonarQube failures have their own, clearer wording', () {
    expect(
      const SonarQubeAccessDeniedFailure().message,
      allOf(contains('SonarQube'), contains('browse')),
    );
    expect(
      const SonarQubeProjectNotFoundFailure().message,
      allOf(contains('project'), contains('refresh')),
    );
  });
}
