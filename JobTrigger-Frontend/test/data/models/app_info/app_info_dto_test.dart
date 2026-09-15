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
          'privacyPolicyUrl': 'https://example.com/privacy',
          'createdAt': '2024-01-01T00:00:00.000Z',
        });

        final domain = dto.toDomain();
        expect(domain.appVersion, '2.3.0');
        expect(domain.buildNumber, '42');
        expect(domain.privacyPolicyUrl, 'https://example.com/privacy');
        expect(domain.termsOfServiceUrl, isNull);
        expect(domain.supportEmail, isNull);
        expect(domain.openSourceLicensesUrl, isNull);
      },
    );
  });
}
