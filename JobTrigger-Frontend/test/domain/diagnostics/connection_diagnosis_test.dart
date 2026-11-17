import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/domain/diagnostics/connection_diagnosis.dart';

void main() {
  group('diagnoseConnection (PI-03 / IMP-35)', () {
    test('a malformed address is a wrong URL', () {
      final result = diagnoseConnection('not a url', const NetworkFailure());
      expect(result.cause, ConnectionCause.wrongUrl);
      expect(result.guide, isNull);
    });

    test('a 404 or an unexpected page is a wrong URL', () {
      for (final failure in <AppFailure>[
        const NotFoundFailure(),
        const UnexpectedResponseFailure(),
      ]) {
        final result = diagnoseConnection(
          'https://ci.example.com/job/thing/',
          failure,
        );
        expect(result.cause, ConnectionCause.wrongUrl, reason: '$failure');
        expect(result.fixTips, isNotEmpty);
      }
    });

    test(
      'a private address on an unreachable host gets home-network advice',
      () {
        for (final url in [
          'http://192.168.1.24:8080',
          'http://10.0.0.5:8080',
          'http://172.20.4.9:8080',
          'http://localhost:8080',
        ]) {
          final result = diagnoseConnection(url, const NetworkFailure());
          expect(result.cause, ConnectionCause.privateAddress, reason: url);
          expect(result.guide, ConnectionGuide.remoteAccess, reason: url);
          expect(result.explanation, contains(Uri.parse(url).host));
        }
      },
    );

    test(
      'a gateway error on a private address is also home-network advice',
      () {
        final result = diagnoseConnection(
          'http://192.168.1.24:8080',
          const ServerFailure(502),
        );
        expect(result.cause, ConnectionCause.privateAddress);
      },
    );

    test('a Tailscale address suggests the VPN is off', () {
      final result = diagnoseConnection(
        'http://100.101.102.103:8080',
        const NetworkFailure(),
      );
      expect(result.cause, ConnectionCause.vpnOff);
      expect(result.explanation, contains('100.101.102.103'));
      expect(result.guide, ConnectionGuide.remoteAccess);
    });

    test('a bad certificate gets certificate advice and a guide', () {
      final result = diagnoseConnection(
        'https://ci.example.com',
        const BadCertificateFailure(),
      );
      expect(result.cause, ConnectionCause.certificate);
      expect(result.guide, ConnectionGuide.remoteAccess);
      expect(result.fixTips, hasLength(3));
    });

    test(
      'a public address with a connection failure is a plain network error',
      () {
        final result = diagnoseConnection(
          'https://ci.example.com:8080',
          const NetworkFailure(),
        );
        expect(result.cause, ConnectionCause.network);
        expect(result.guide, isNull);
      },
    );

    test('an answered-but-failed request falls back to a generic cause', () {
      final result = diagnoseConnection(
        'https://ci.example.com',
        const AuthFailure(),
      );
      expect(result.cause, ConnectionCause.other);
      expect(result.title, isNotEmpty);
    });

    test('the checklist covers all five common causes', () {
      final causes = connectionChecklist().map((item) => item.cause).toSet();
      expect(causes, {
        ConnectionCause.wrongUrl,
        ConnectionCause.privateAddress,
        ConnectionCause.vpnOff,
        ConnectionCause.certificate,
        ConnectionCause.network,
      });
    });
  });
}
