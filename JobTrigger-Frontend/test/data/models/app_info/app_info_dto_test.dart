import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/models/app_info/app_info_dto.dart';

void main() {
  group('AppInfoDto', () {
    // Mongo's real id key is `_id` -- same field-name risk as the other
    // backend-sourced DTOs.
    test('parses the real _id field name and every other field', () {
      final dto = AppInfoDto.fromJson({
        '_id': 'info-1',
        'appVersion': '2.3.0',
        'buildNumber': '42',
        'privacyPolicyUrl': 'https://example.com/privacy',
        'termsOfServiceUrl': 'https://example.com/terms',
        'supportEmail': 'support@example.com',
        'openSourceLicensesUrl': 'https://example.com/licenses',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-02T00:00:00.000Z',
      });

      expect(dto.id, 'info-1');
      expect(dto.appVersion, '2.3.0');
      expect(dto.buildNumber, '42');
      expect(dto.privacyPolicyUrl, 'https://example.com/privacy');
      expect(dto.termsOfServiceUrl, 'https://example.com/terms');
      expect(dto.supportEmail, 'support@example.com');
      expect(dto.openSourceLicensesUrl, 'https://example.com/licenses');
      expect(dto.createdAt, '2024-01-01T00:00:00.000Z');
      expect(dto.updatedAt, '2024-01-02T00:00:00.000Z');
    });

    // US-PROF-03: release notes link and the forced-update minimum.
    test('parses releaseNotesUrl and minSupportedVersion', () {
      final info = AppInfoDto.fromJson({
        '_id': 'info-1',
        'appVersion': '1.0.0',
        'buildNumber': '7',
        'releaseNotesUrl': 'https://jobtrigger.app/changelog',
        'minSupportedVersion': '1.0.1',
      }).toDomain();

      expect(info.releaseNotesUrl, 'https://jobtrigger.app/changelog');
      expect(info.minSupportedVersion, '1.0.1');
    });

    test('leaves every optional field null when absent', () {
      final dto = AppInfoDto.fromJson({
        '_id': 'info-1',
        'appVersion': '2.3.0',
        'buildNumber': '42',
      });

      expect(dto.privacyPolicyUrl, isNull);
      expect(dto.termsOfServiceUrl, isNull);
      expect(dto.supportEmail, isNull);
      expect(dto.openSourceLicensesUrl, isNull);
      expect(dto.createdAt, isNull);
      expect(dto.updatedAt, isNull);
    });

    test(
      'toDomain() drops storage bookkeeping fields (id, createdAt, updatedAt)',
      () {
        final dto = AppInfoDto.fromJson({
          '_id': 'info-1',
          'appVersion': '2.3.0',
          'buildNumber': '42',
          'privacyPolicyUrl': 'https://jobtrigger.app/privacy',
          'createdAt': '2024-01-01T00:00:00.000Z',
        });

        final domain = dto.toDomain();
        expect(domain.appVersion, '2.3.0');
        expect(domain.buildNumber, '42');
        expect(domain.privacyPolicyUrl, 'https://jobtrigger.app/privacy');
        expect(domain.termsOfServiceUrl, isNull);
        expect(domain.supportEmail, isNull);
        expect(domain.openSourceLicensesUrl, isNull);
      },
    );

    // PE-05: placeholder links from an unconfigured backend are hidden.
    test('toDomain() drops placeholder and non-http links', () {
      final domain = AppInfoDto.fromJson({
        '_id': 'info-1',
        'appVersion': '1.0.0',
        'buildNumber': '1',
        'privacyPolicyUrl': 'https://example.com/privacy',
        'termsOfServiceUrl': 'https://docs.example.org/terms',
        'openSourceLicensesUrl': 'javascript:alert(1)',
      }).toDomain();

      expect(domain.privacyPolicyUrl, isNull);
      expect(domain.termsOfServiceUrl, isNull);
      expect(domain.openSourceLicensesUrl, isNull);
    });

    test('toDomain() keeps real links, trimmed', () {
      final domain = AppInfoDto.fromJson({
        '_id': 'info-1',
        'appVersion': '1.0.0',
        'buildNumber': '1',
        'privacyPolicyUrl': ' https://jobtrigger.app/privacy ',
        'termsOfServiceUrl': 'http://192.168.1.20:3000/terms',
      }).toDomain();

      expect(domain.privacyPolicyUrl, 'https://jobtrigger.app/privacy');
      expect(domain.termsOfServiceUrl, 'http://192.168.1.20:3000/terms');
    });
  });
}
