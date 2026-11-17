import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/platform/temp_files.dart';

void main() {
  group('safeFileName (AUD-50)', () {
    test('keeps an ordinary name as it is', () {
      expect(safeFileName('app-release 1.2.apk'), 'app-release 1.2.apk');
      expect(safeFileName('rapport été.pdf'), 'rapport été.pdf');
    });

    test('keeps only the last path segment', () {
      expect(safeFileName('../../shared_prefs/x.xml'), 'x.xml');
      expect(safeFileName(r'..\..\evil.dll'), 'evil.dll');
      expect(safeFileName('/etc/passwd'), 'passwd');
    });

    test('falls back for nothing usable', () {
      for (final name in ['', '..', '.', 'dir/', '  ', '\u0000']) {
        expect(
          safeFileName(name, fallback: 'artifact'),
          'artifact',
          reason: name,
        );
      }
    });

    test('drops control characters', () {
      expect(safeFileName('a\nb\u0007.txt'), 'ab.txt');
    });
  });
}
