import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/onboarding/whats_new.dart';

void main() {
  test('matches the release by major.minor', () {
    expect(whatsNewFor('1.0.0')?.version, '1.0');
    expect(whatsNewFor('1.0.1')?.version, '1.0');
  });

  test('has nothing to say about a version with no entry', () {
    expect(whatsNewFor('1.1.0'), isNull);
    expect(whatsNewFor(''), isNull);
  });

  test('the 1.0 notes name the three tools', () {
    final notes = whatsNewFor('1.0.0')!;
    expect(notes.items.first, contains('Jenkins'));
    expect(notes.items.first, contains('GitHub Actions'));
    expect(notes.items.first, contains('SonarQube'));
  });
}
