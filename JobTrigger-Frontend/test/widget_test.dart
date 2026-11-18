import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:job_trigger/main.dart';
import 'package:job_trigger/core/theme/app_theme.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  testWidgets('app starts on the login screen when logged out', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('app scroll behavior uses clamping physics', (tester) async {
    late ScrollPhysics physics;

    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: AppTheme.scrollBehavior(),
        home: Builder(
          builder: (context) {
            physics = ScrollConfiguration.of(context).getScrollPhysics(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(physics, isA<ClampingScrollPhysics>());
  });
}
