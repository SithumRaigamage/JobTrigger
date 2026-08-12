import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/storage/secure_storage_service.dart';

void main() {
  late SecureStorageService service;

  setUp(() {
    // The package's in-memory test implementation — see
    // FlutterSecureStorage.setMockInitialValues.
    FlutterSecureStorage.setMockInitialValues({});
    service = SecureStorageService(const FlutterSecureStorage());
  });

  test('readToken returns null when nothing has been saved', () async {
    expect(await service.readToken(), isNull);
  });

  test('saveToken then readToken round-trips the value', () async {
    await service.saveToken('abc123');

    expect(await service.readToken(), 'abc123');
  });

  test('clear removes the saved token', () async {
    await service.saveToken('abc123');

    await service.clear();

    expect(await service.readToken(), isNull);
  });
}
