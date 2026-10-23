import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/history_entry.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/relative_time.dart';

HistoryEntry _entry(String job, DateTime started) => HistoryEntry(
  jobName: job,
  build: JenkinsBuild(
    number: 1,
    url: 'https://ci.test/job/$job/1/',
    timestamp: started.millisecondsSinceEpoch.toDouble(),
  ),
);

/// P14-09: Global History's day sections.
void main() {
  group('groupHistoryByDay', () {
    test('splits newest-first entries by the day they started', () {
      final groups = groupHistoryByDay([
        _entry('a', DateTime(2026, 10, 23, 10, 42)),
        _entry('b', DateTime(2026, 10, 23, 8, 51)),
        _entry('c', DateTime(2026, 10, 22, 17, 5)),
      ]);

      expect(groups.map((g) => g.$1), [
        DateTime(2026, 10, 23),
        DateTime(2026, 10, 22),
      ]);
      expect(groups.first.$2.map((e) => e.jobName), ['a', 'b']);
      expect(groups.last.$2.single.jobName, 'c');
    });

    test('nothing to group gives no sections', () {
      expect(groupHistoryByDay(const []), isEmpty);
    });
  });

  group('dayLabel', () {
    final now = DateTime(2026, 10, 23, 9);

    test('today and yesterday by name', () {
      expect(dayLabel(DateTime(2026, 10, 23), now: now), 'Today');
      expect(dayLabel(DateTime(2026, 10, 22), now: now), 'Yesterday');
    });

    test('older days by weekday and date', () {
      expect(dayLabel(DateTime(2026, 10, 19), now: now), 'Mon 19 Oct');
    });

    test('another year carries the year', () {
      expect(dayLabel(DateTime(2025, 12, 31), now: now), 'Wed 31 Dec 2025');
    });
  });

  test('clockTime pads to HH:MM, and HH:MM:SS with seconds', () {
    expect(clockTime(DateTime(2026, 1, 1, 8, 5)), '08:05');
    expect(clockTime(DateTime(2026, 1, 1, 8, 5, 9), seconds: true), '08:05:09');
  });
}
