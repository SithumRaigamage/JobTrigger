import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/presentation/features/build_log/build_log_toolbar.dart';

void main() {
  testWidgets('log toolbar keeps actions reachable at 320pt and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                BuildLogToolbar(
                  title: 'Console',
                  subtitle:
                      'A very long job name and build identifier · 50,000 lines',
                  onBack: () {},
                  actions: [
                    IconButton(
                      tooltip: 'Copy log',
                      onPressed: () {},
                      icon: const Icon(Icons.copy_rounded),
                    ),
                    IconButton(
                      tooltip: 'Share log',
                      onPressed: () {},
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
                    IconButton(
                      tooltip: 'More log actions',
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Copy log'), findsOneWidget);
    expect(find.byTooltip('Share log'), findsOneWidget);
    expect(find.byTooltip('More log actions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
