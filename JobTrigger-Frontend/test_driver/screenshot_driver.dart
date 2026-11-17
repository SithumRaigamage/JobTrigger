import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Writes each `takeScreenshot` PNG into $SCREENSHOT_DIR (default
/// `store-screenshots/`), for `integration_test/store_screenshots_test.dart`.
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final dir = Directory(
      Platform.environment['SCREENSHOT_DIR'] ?? 'store-screenshots',
    )..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes);
    return true;
  },
);
