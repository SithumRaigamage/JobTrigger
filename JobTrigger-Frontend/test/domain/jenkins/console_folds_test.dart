import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/console_decoder.dart';
import 'package:job_trigger/domain/jenkins/console_folds.dart';

List<ConsoleLine> _decode(List<String> lines) =>
    ConsoleDecoder().addChunk([for (final line in lines) '$line\n'].join());

List<String> _describe(List<ConsoleSection> sections) => [
  for (final section in sections)
    section.isFold
        ? 'fold ${section.firstLine}-${section.lastLine}'
        : 'line ${section.firstLine}',
];

/// NR-01: folding noisy console sections.
void main() {
  test('folds a run of lines that differ only in numbers', () {
    final lines = _decode([
      for (var i = 1; i <= 6; i++) 'Downloading $i/6',
      'Build finished',
    ]);

    expect(_describe(foldConsole(lines)), ['fold 0-5', 'line 6']);
  });

  test('keeps a run shorter than the minimum as individual lines', () {
    final lines = _decode(['retrying', 'retrying', 'retrying']);

    expect(_describe(foldConsole(lines)), ['line 0', 'line 1', 'line 2']);
  });

  test('never folds a line that looks like a failure', () {
    final lines = _decode([
      'Waiting for executor',
      'Waiting for executor',
      'Waiting for executor',
      'Waiting for executor',
      'ERROR: stage failed',
      'Waiting for executor',
      'Waiting for executor',
      'Waiting for executor',
      'Waiting for executor',
    ]);

    expect(_describe(foldConsole(lines)), ['fold 0-3', 'line 4', 'fold 5-8']);
  });

  test('a repeated stack trace stays readable line by line', () {
    final lines = _decode([
      for (var i = 0; i < 5; i++) 'Exception: no such file or directory',
    ]);

    expect(_describe(foldConsole(lines)), [
      'line 0',
      'line 1',
      'line 2',
      'line 3',
      'line 4',
    ]);
  });

  test('blank filler is noise like any other', () {
    final lines = _decode(['start', '', '', '', '', 'end']);

    expect(_describe(foldConsole(lines)), ['line 0', 'fold 1-4', 'line 5']);
  });

  test('a fold splits where the signature changes', () {
    final lines = _decode([
      'Compiling 1 of 3',
      'Compiling 2 of 3',
      'Compiling 3 of 3',
      'Compiling 4 of 3',
      'Linking',
      'Linking',
      'Linking',
      'Linking',
    ]);

    expect(_describe(foldConsole(lines)), ['fold 0-3', 'fold 4-7']);
  });

  test('signatures ignore case, ids, numbers and spacing', () {
    expect(
      consoleLineSignature('Built  abc1234   in 1.4s'),
      consoleLineSignature('built ABC1234 in 12s'),
    );
    expect(
      consoleLineSignature('Downloading 1/50'),
      isNot(consoleLineSignature('Downloading complete')),
    );
  });

  test('finds the section that holds a line', () {
    final sections = foldConsole(
      _decode([for (var i = 0; i < 5; i++) 'tick $i', 'done']),
    );

    expect(sectionIndexForLine(sections, 0), 0);
    expect(sectionIndexForLine(sections, 4), 0);
    expect(sectionIndexForLine(sections, 5), 1);
    expect(sectionIndexForLine(sections, 6), isNull);
  });

  test('every line is in exactly one section', () {
    final lines = _decode([
      'a',
      'b',
      'b',
      'ERROR x',
      'c',
      for (var i = 0; i < 4; i++) 'd$i',
    ]);

    final sections = foldConsole(lines);
    var next = 0;
    for (final section in sections) {
      expect(section.firstLine, next);
      next = section.lastLine + 1;
    }
    expect(next, lines.length);
  });
}
