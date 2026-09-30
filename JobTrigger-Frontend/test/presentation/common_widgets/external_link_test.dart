import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/platform/link_launcher.dart';
import 'package:job_trigger/presentation/common_widgets/external_link.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';

void main() {
  Future<ProviderContainer> pumpButton(
    WidgetTester tester, {
    required bool handled,
    required List<Uri> opened,
    required Uri uri,
  }) async {
    final container = ProviderContainer(
      overrides: [
        linkLauncherProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return handled;
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(currentToastProvider, (_, _) {});
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => openExternalLink(ref, uri),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    return container;
  }

  testWidgets('an opened link shows nothing extra', (tester) async {
    final opened = <Uri>[];
    final uri = Uri.parse('https://example.com/privacy');
    final container = await pumpButton(
      tester,
      handled: true,
      opened: opened,
      uri: uri,
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(opened, [uri]);
    expect(container.read(currentToastProvider), isNull);
  });

  testWidgets('a link nothing can open says so (AUD-22)', (tester) async {
    final container = await pumpButton(
      tester,
      handled: false,
      opened: [],
      uri: Uri.parse('https://example.com/privacy'),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    final toast = container.read(currentToastProvider);
    expect(toast?.title, "Couldn't open link");
    expect(toast?.message, contains('example.com'));
    await tester.pump(const Duration(seconds: 4)); // Toast auto-dismiss.
  });

  testWidgets('a mail link without a mail app names the address', (
    tester,
  ) async {
    final container = await pumpButton(
      tester,
      handled: false,
      opened: [],
      uri: Uri.parse('mailto:support@example.com'),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();

    expect(
      container.read(currentToastProvider)?.message,
      'No email app is set up. Write to support@example.com.',
    );
    await tester.pump(const Duration(seconds: 4));
  });
}
