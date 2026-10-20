import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/html_text.dart';
import 'package:job_trigger/domain/jenkins/relative_time.dart';

void main() {
  test('strips tags and keeps line structure (US-JX-14)', () {
    expect(htmlToPlainText('<b>Release</b> v1.2'), 'Release v1.2');
    expect(htmlToPlainText('one<br>two<br/>three'), 'one\ntwo\nthree');
    expect(htmlToPlainText('<p>a</p><p>b</p>'), 'a\nb');
  });

  test('never lets markup through, even script', () {
    final text = htmlToPlainText(
      '<script>alert(1)</script><a href="x">link</a>',
    );
    expect(text, isNot(contains('<')));
    expect(text, 'alert(1)link');
  });

  test('decodes entities, with &amp; last', () {
    expect(htmlToPlainText('a &lt;b&gt; &amp; &quot;c&quot;'), 'a <b> & "c"');
    expect(htmlToPlainText('&amp;lt;'), '&lt;');
  });

  test('formatBuildDuration', () {
    expect(formatBuildDuration(400), '<1s');
    expect(formatBuildDuration(42000), '42s');
    expect(formatBuildDuration(252000), '4m 12s');
    expect(formatBuildDuration(3780000), '1h 3m');
  });
}
