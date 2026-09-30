import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/relative_time.dart';

void main() {
  final now = DateTime(2026, 9, 30, 12);

  test('buckets elapsed time compactly', () {
    String ago(Duration elapsed) =>
        relativeTime(now.subtract(elapsed), now: now);

    expect(ago(const Duration(seconds: 20)), 'just now');
    expect(ago(const Duration(minutes: 5)), '5m ago');
    expect(ago(const Duration(hours: 2)), '2h ago');
    expect(ago(const Duration(days: 3)), '3d ago');
    expect(ago(const Duration(days: 65)), '2mo ago');
    expect(ago(const Duration(days: 800)), '2y ago');
  });

  test('a future timestamp (clock skew) reads as just now', () {
    expect(
      relativeTime(now.add(const Duration(minutes: 3)), now: now),
      'just now',
    );
  });
}
