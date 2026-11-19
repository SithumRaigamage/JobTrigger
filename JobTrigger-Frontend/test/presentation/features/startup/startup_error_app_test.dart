import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/features/startup/startup_error_app.dart';

void main() {
  testWidgets('shows the reason and retries', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      StartupErrorApp(
        message: 'This build has no backend configuration.',
        onRetry: () => retries++,
      ),
    );

    expect(find.text('JobTrigger could not start'), findsOneWidget);
    expect(
      find.text('This build has no backend configuration.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('fits a small screen at 200% text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: StartupErrorApp(
          message:
              'The app took too long to start. Check this build’s '
              'configuration and connection, then try again.',
          onRetry: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Try again'), findsOneWidget);
  });
}
