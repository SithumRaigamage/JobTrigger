import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The repo's one release manifest and this app's copy of it must be
/// identical (scripts/sync-tools.mjs). A failure means someone edited one
/// without running `node scripts/sync-tools.mjs`.
void main() {
  test('config/tools.json is byte-identical to release/tools.json', () {
    final source = File('../release/tools.json');
    final copy = File('config/tools.json');
    expect(
      source.existsSync(),
      isTrue,
      reason: 'run from JobTrigger-Frontend/',
    );
    expect(copy.readAsStringSync(), source.readAsStringSync());
  });

  test('the manifest is bundled as an asset, so a release build reads it', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- config/tools.json'),
    );
  });
}
