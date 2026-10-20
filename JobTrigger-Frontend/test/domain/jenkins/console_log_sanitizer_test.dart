import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/console_log_sanitizer.dart';

const _esc = '\x1B';

void main() {
  group('sanitizeConsoleLog', () {
    test(
      'drops a concealed console note entirely, not just its escape codes',
      () {
        // Real shape captured from a live Jenkins server (US-PIPE-02's
        // "Started by user" line) -- Jenkins hides a base64 payload for its
        // own web UI using SGR 8 (conceal), which a plain text viewer must
        // drop along with the escape codes, not render as visible garbage.
        const raw =
            'Started by user $_esc[8mha:////4FHh5qC0CeAdreJD5jvQLVcU$_esc[0m'
            'Sithum Raigamage';

        expect(sanitizeConsoleLog(raw), 'Started by user Sithum Raigamage');
      },
    );

    test('strips plain ANSI color/formatting codes, keeping the text', () {
      const raw = '$_esc[32mBUILD SUCCESS$_esc[0m';

      expect(sanitizeConsoleLog(raw), 'BUILD SUCCESS');
    });

    test('strips an OSC hyperlink sequence terminated by BEL', () {
      const raw = '$_esc]8;;http://example.com\x07click here$_esc]8;;\x07';

      expect(sanitizeConsoleLog(raw), 'click here');
    });

    test('leaves plain text with no escape sequences untouched', () {
      const raw = '[Pipeline] { (Declarative: Checkout SCM)';

      expect(sanitizeConsoleLog(raw), raw);
    });

    test('handles multiple concealed notes on the same line', () {
      const raw = '$_esc[8mAAA$_esc[0mHello $_esc[8mBBB$_esc[0mWorld';

      expect(sanitizeConsoleLog(raw), 'Hello World');
    });
  });
}
