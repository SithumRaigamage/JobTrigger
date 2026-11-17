@Tags(['fixture'])
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_support.dart';

/// P11-16 / US-JX-18: version and quiet-down, toggled for real.
void main() {
  // Lazy: `main()` still runs when the `fixture` tag is skipped.
  late final jenkins = FixtureJenkins.fromEnvironment();

  test('reports the version and follows quiet-down', () async {
    final repository = jenkins.adminRepository();
    final admin = jenkins.adminDio();

    var status = expectOk(await repository.fetchServerStatus());
    expect(status.version, '2.568.3');
    expect(status.quietingDown, isFalse);

    // Jenkins answers these with a 302; only the effect matters here.
    Future<void> post(String path) => admin.post<void>(
      path,
      options: Options(followRedirects: false, validateStatus: (_) => true),
    );
    await post('/quietDown');
    addTearDown(() => post('/cancelQuietDown'));

    status = expectOk(await repository.fetchServerStatus());
    expect(status.quietingDown, isTrue);
  });
}
