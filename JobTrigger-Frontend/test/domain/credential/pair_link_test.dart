import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/credential/pair_link.dart';

/// NR-03: the shape the website's QR carries and the app reads.
void main() {
  test('round-trips the link the website builds', () {
    final link = PairLink.build(
      jenkinsURL: 'https://ci.example.com',
      serverName: 'Acme production',
      username: 'deploy',
    );

    final parsed = PairLink.fromUri(Uri.parse(link));

    expect(parsed, isNotNull);
    expect(parsed!.jenkinsURL, 'https://ci.example.com');
    expect(parsed.serverName, 'Acme production');
    expect(parsed.username, 'deploy');
  });

  test('keeps an address that carries its own query string', () {
    const address = 'https://ci.example.com/?folder=release';
    final parsed = PairLink.fromUri(
      Uri.parse(PairLink.build(jenkinsURL: address, serverName: 'Release')),
    );

    expect(parsed!.jenkinsURL, address);
    expect(parsed.username, isEmpty);
  });

  test('ignores a link that is not a pairing link', () {
    expect(
      PairLink.fromUri(Uri.parse('jobtrigger://app/open?url=https://a.test')),
      isNull,
    );
    expect(PairLink.fromUri(Uri.parse('https://a.test/pair?url=x')), isNull);
  });

  test('needs both an address and a name', () {
    expect(PairLink.fromQuery(const {'name': 'Acme'}), isNull);
    expect(PairLink.fromQuery(const {'url': 'https://ci.test'}), isNull);
    expect(PairLink.fromQuery(const {'url': ' ', 'name': ' '}), isNull);
    expect(
      PairLink.fromQuery(const {
        'url': ' https://ci.test ',
        'name': ' Acme ',
      })?.serverName,
      'Acme',
    );
  });
}
