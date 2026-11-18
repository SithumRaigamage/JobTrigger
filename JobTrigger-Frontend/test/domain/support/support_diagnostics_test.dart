import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/support/support_diagnostics.dart';

void main() {
  group('hostOnly (P25-05)', () {
    test('keeps scheme, host and an explicit port', () {
      expect(
        hostOnly('https://ci.example.com:8443/job/api/'),
        'https://ci.example.com:8443',
      );
      expect(hostOnly('http://localhost:8080'), 'http://localhost:8080');
    });

    test('drops the path, query, fragment and any credentials', () {
      expect(
        hostOnly('https://user:pass@ci.example.com/job/x?token=abc#top'),
        'https://ci.example.com',
      );
    });

    test('refuses anything that is not http(s), and empty input', () {
      expect(hostOnly(null), isNull);
      expect(hostOnly(''), isNull);
      expect(hostOnly('ftp://ci.example.com'), isNull);
      expect(hostOnly('not a url'), isNull);
    });
  });

  test('the summary is the line the form shows, without a job path', () {
    const diagnostics = SupportDiagnostics(
      appVersion: '1.0.0',
      buildNumber: '7',
      tool: 'jenkins',
      platform: 'ios',
      serverHost: 'https://ci.example.com',
    );

    expect(
      diagnostics.summary,
      'Version 1.0.0 (7) · jenkins · ios · https://ci.example.com',
    );
    expect(diagnostics.toJson(), {
      'appVersion': '1.0.0',
      'buildNumber': '7',
      'tool': 'jenkins',
      'platform': 'ios',
      'serverHost': 'https://ci.example.com',
    });
  });
}
