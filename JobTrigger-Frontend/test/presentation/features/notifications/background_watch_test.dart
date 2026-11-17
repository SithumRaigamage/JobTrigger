import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/features/notifications/background_watch.dart';

void main() {
  test('only Android and iOS hosts schedule background checks', () {
    expect(
      BackgroundWatchScheduler().isSupported,
      Platform.isAndroid || Platform.isIOS,
    );
  });

  // AUD-42: on a Linux CI host the plugin shelled out to systemd and left a
  // pending timer behind, failing whichever widget test reached it.
  testWidgets('an unsupported host never reaches the plugin', (tester) async {
    final scheduler = BackgroundWatchScheduler(isSupported: false);
    await scheduler.sync(hasWatches: true);
    await scheduler.sync(hasWatches: false);
    // The test framework fails here if anything left a timer pending.
  });
}
