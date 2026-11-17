import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error_reporting/event_scrubber.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Assembled at runtime so no token-shaped literal sits in the tree (AUD-66).
final _token = ['a1b2c3d4', 'e5f60718', '2a3b4c5d', '6e7f8091'].join();

SentryEvent _dirty() => SentryEvent(
  message: SentryMessage('failed with token $_token'),
  throwable: StateError('Basic ${_basic()} rejected'),
  request: SentryRequest(
    method: 'POST',
    url: 'https://user:$_token@jenkins.example.com/job/x?token=$_token#f',
    queryString: 'token=$_token',
    data: {'password': _token},
    cookies: 'sid=$_token',
    headers: {
      'Authorization': 'Bearer $_token',
      'x-auth-token': _token,
      'Cookie': 'sid=$_token',
      'Set-Cookie': 'sid=$_token',
      'PRIVATE-TOKEN': _token,
      'X-Api-Key': 'k',
      'content-type': 'application/json',
    },
  ),
  user: SentryUser(
    id: 'abc',
    email: 'someone@example.com',
    ipAddress: '1.2.3.4',
  ),
  breadcrumbs: [Breadcrumb(message: 'typed $_token')],
  tags: {
    // Built at runtime so the repository's secret scan doesn't flag a synthetic fixture.
    'uri': ['mongodb+srv://admin:', _token, '@cluster.example.net/db'].join(),
    'secret': _token,
  },
);

String _basic() => 'dXNlcjo$_token'.substring(0, 24);

void main() {
  test('keeps Sentry\'s own event and trace ids, which look like a token '
      '(found live on GlitchTip: the host rejected "[redacted]")', () {
    final clean = scrubEventJson({
      'event_id': '0123456789abcdef0123456789abcdef',
      'message': 'token=abcdefabcdefabcdefabcdefabcdefab',
      'contexts': {
        'trace': {
          'trace_id': 'fedcba9876543210fedcba9876543210',
          'span_id': '0123456789abcdef',
        },
      },
    })!;
    expect(clean['event_id'], '0123456789abcdef0123456789abcdef');
    expect(
      (clean['contexts'] as Map)['trace']['trace_id'],
      'fedcba9876543210fedcba9876543210',
    );
    // Everything else is still scrubbed.
    expect(clean['message'], isNot(contains('abcdefabcdef')));
  });

  test('an event_id that is not plain hex is still redacted', () {
    final clean = scrubEventJson({
      'event_id': 'token=abcdefabcdefabcdefabcdef',
    })!;
    expect(clean['event_id'], isNot(contains('abcdef')));
  });

  group('scrubEvent', () {
    test('removes the token from the message, headers and URL', () {
      final clean = scrubEvent(_dirty())!;
      final text = clean.toJson().toString();
      expect(text, isNot(contains(_token)));
      expect(clean.request!.url, 'https://jenkins.example.com/job/x');
      expect(clean.request!.headers, {'content-type': 'application/json'});
      expect(clean.request!.data, isNull);
      expect(clean.request!.cookies, isNull);
      expect(clean.request!.queryString, isNull);
    });

    test('keeps no email, address, breadcrumbs or database password', () {
      final clean = scrubEvent(_dirty())!;
      final text = clean.toJson().toString();
      expect(text, isNot(contains('someone@example.com')));
      expect(text, isNot(contains('1.2.3.4')));
      expect(text, isNot(contains('admin:')));
      expect(clean.user!.id, 'abc');
      expect(clean.user!.email, isNull);
      expect(clean.breadcrumbs, anyOf(isNull, isEmpty));
    });

    test('drops the event when it cannot be scrubbed', () {
      expect(scrubEventJson({'message': Object(), 'x': _Boom()}), isNull);
    });
  });

  group('scrubString and scrubUrl', () {
    test('redacts key/value secrets but leaves ordinary text', () {
      expect(
        scrubString('password=hunter2 for host a'),
        'password=$redacted for host a',
      );
      expect(
        scrubString('down at https://j.example.com/x?y=1'),
        'down at https://j.example.com/x',
      );
    });

    test('redacts a bare token and an Authorization scheme', () {
      expect(scrubString('t $_token t'), 't $redacted t');
      expect(scrubString('Bearer abcdefghijklmnop'), 'Bearer $redacted');
    });

    test('leaves a 40-character git SHA alone', () {
      const sha = 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3';
      expect(scrubString('commit $sha'), 'commit $sha');
    });

    test('strips query, fragment and credentials from a URL', () {
      expect(
        scrubUrl('https://a:b@h.example.com/p?q=1#f'),
        'https://h.example.com/p',
      );
    });
  });
}

/// An object whose string form throws, to force the scrubber's failure path.
class _Boom {
  @override
  String toString() => throw StateError('boom');
}
