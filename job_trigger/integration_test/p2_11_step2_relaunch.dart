// TEMPORARY manual P2-11 real-device verification, step 2 of 2.
// Run AFTER p2_11_step1_signup.dart on the SAME device -- a brand new app
// process pumping MyApp fresh, reusing whatever step 1 already persisted
// to the simulator's real Keychain/shared_preferences. If this lands
// straight on ToolSelectionScreen without ever showing LoginScreen, that's
// the real "kill and relaunch while logged in -> lands on home, not
// login" check P2-11 asks for. Not part of the permanent suite -- delete
// both files after use.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:job_trigger/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a fresh app launch with a persisted session lands on ToolSelectionScreen, not Login',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Choose Your Tool'), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
      // ignore: avoid_print
      print('P2-11 step 2: fresh launch landed on ToolSelectionScreen, not Login.');
    },
  );
}
