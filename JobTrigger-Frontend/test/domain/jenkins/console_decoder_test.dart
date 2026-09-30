import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/console_decoder.dart';

const esc = '\x1B';

List<String> texts(List<ConsoleLine> lines) => [
  for (final line in lines) line.text,
];

void main() {
  test('splits lines and keeps the unfinished one pending', () {
    final decoder = ConsoleDecoder();
    expect(texts(decoder.addChunk('one\ntwo\nthr')), ['one', 'two']);
    expect(decoder.pendingLine?.text, 'thr');
    expect(texts(decoder.addChunk('ee\n')), ['three']);
    expect(decoder.pendingLine, isNull);
  });

  test('CRLF is a normal line end, even split across chunks (AUD-34)', () {
    final decoder = ConsoleDecoder();
    expect(texts(decoder.addChunk('a\r\nb\r')), ['a']);
    expect(texts(decoder.addChunk('\nc\n')), ['b', 'c']);
  });

  test('a bare carriage return overwrites the line (progress bars)', () {
    final decoder = ConsoleDecoder();
    expect(texts(decoder.addChunk('10%\r50%\r100%\n')), ['100%']);
  });

  test('renders SGR colors and bold instead of stripping them', () {
    final line = ConsoleDecoder()
        .addChunk('$esc[1;31mERROR$esc[0m: boom\n')
        .single;

    expect(line.text, 'ERROR: boom');
    expect(line.spans.first.text, 'ERROR');
    expect(line.spans.first.style.bold, isTrue);
    expect(line.spans.first.style.foreground, const ConsoleColor.indexed(1));
    expect(line.spans.last.style, ConsoleStyle.plain);
  });

  test('bright, 256-color and truecolor', () {
    final spans = ConsoleDecoder()
        .addChunk('$esc[92ma$esc[38;5;208mb$esc[48;2;16;32;48mc\n')
        .single
        .spans;

    expect(spans[0].style.foreground, const ConsoleColor.indexed(10));
    expect(spans[1].style.foreground, const ConsoleColor.indexed(208));
    expect(spans[2].style.background, const ConsoleColor.rgb(0x102030));
  });

  test('style carries across lines and chunks, like a terminal', () {
    final decoder = ConsoleDecoder();
    decoder.addChunk('$esc[32mgreen\n');
    final next = decoder.addChunk('still green\n').single;
    expect(next.spans.single.style.foreground, const ConsoleColor.indexed(2));
  });

  test('drops Jenkins console-note payloads (ESC[8m…ESC[0m)', () {
    final line = ConsoleDecoder()
        .addChunk('Started by user $esc[8mha:////4Bp0lo3G==$esc[0mAdmin\n')
        .single;
    expect(line.text, 'Started by user Admin');
  });

  test(
    'an escape sequence cut across chunks is completed, not leaked (AUD-34)',
    () {
      final decoder = ConsoleDecoder();
      expect(decoder.addChunk('ok $esc['), isEmpty);
      final line = decoder.addChunk('31mred\n').single;
      expect(line.text, 'ok red');
      expect(line.spans.last.style.foreground, const ConsoleColor.indexed(1));
    },
  );

  test('a console note split across chunks stays hidden', () {
    final decoder = ConsoleDecoder()..addChunk('a $esc[8mha:////secretpay');
    final line = decoder.addChunk('load$esc[0mb\n').single;
    expect(line.text, 'a b');
  });

  test('OSC hyperlinks are dropped', () {
    final line = ConsoleDecoder()
        .addChunk('see $esc]8;;https://x\x07link$esc]8;;\x07\n')
        .single;
    expect(line.text, 'see link');
  });

  test('isErrorLine and searchLines', () {
    expect(isErrorLine('[ERROR] compile failed'), isTrue);
    expect(isErrorLine('java.lang.IllegalStateException: x'), isFalse);
    expect(isErrorLine('Caught Exception while'), isTrue);
    expect(isErrorLine('errors: 0'), isFalse);

    final lines = ConsoleDecoder().addChunk('Alpha\nbeta\nALPHABET\n');
    expect(searchLines(lines, 'alpha'), [0, 2]);
    expect(searchLines(lines, ''), isEmpty);
  });

  test('decodes a 50,000-line log in one pass quickly (AUD-12)', () {
    final chunk = StringBuffer();
    for (var i = 0; i < 50000; i++) {
      chunk.write('$esc[32mINFO$esc[0m line $i\n');
    }
    final stopwatch = Stopwatch()..start();
    final lines = ConsoleDecoder().addChunk(chunk.toString());
    stopwatch.stop();

    expect(lines, hasLength(50000));
    expect(lines.last.text, 'INFO line 49999');
    expect(stopwatch.elapsedMilliseconds, lessThan(2000));
  });

  test('lifts the embedded Timestamper prefix off pipeline lines', () {
    final lines = ConsoleDecoder().addChunk(
      '[2026-09-30T05:33:00.175Z] $esc[32mINFO$esc[0m line 1\r\n'
      'no stamp here\r\n',
    );

    expect(lines[0].text, 'INFO line 1');
    expect(lines[0].timestamp, DateTime.utc(2026, 9, 30, 5, 33, 0, 175));
    expect(
      lines[0].spans.first.style.foreground,
      const ConsoleColor.indexed(2),
    );
    expect(lines[1].timestamp, isNull);
    expect(lines[1].text, 'no stamp here');
  });
}
