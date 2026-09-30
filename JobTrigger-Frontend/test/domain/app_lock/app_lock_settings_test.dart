import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/app_lock/app_lock_settings.dart';

void main() {
  final now = DateTime(2026, 9, 30, 12);
  const on = AppLockSettings(enabled: true);

  test('never locks while the lock is off', () {
    expect(
      shouldLockOnResume(
        settings: const AppLockSettings(),
        backgroundedAt: now.subtract(const Duration(hours: 1)),
        now: now,
      ),
      isFalse,
    );
  });

  test('stays unlocked for a short trip away', () {
    expect(
      shouldLockOnResume(
        settings: on,
        backgroundedAt: now.subtract(const Duration(minutes: 4)),
        now: now,
      ),
      isFalse,
    );
  });

  test('locks once the timeout has passed (US-JX-21)', () {
    expect(
      shouldLockOnResume(
        settings: on,
        backgroundedAt: now.subtract(const Duration(minutes: 5)),
        now: now,
      ),
      isTrue,
    );
  });

  test('"Immediately" locks after any trip away', () {
    expect(
      shouldLockOnResume(
        settings: on.copyWith(timeout: Duration.zero),
        backgroundedAt: now,
        now: now,
      ),
      isTrue,
    );
  });

  test('without a backgrounding there is nothing to lock', () {
    expect(
      shouldLockOnResume(settings: on, backgroundedAt: null, now: now),
      isFalse,
    );
  });
}
