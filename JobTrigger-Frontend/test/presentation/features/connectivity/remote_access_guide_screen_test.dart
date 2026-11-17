import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/platform/link_launcher.dart';
import 'package:job_trigger/presentation/features/connectivity/remote_access_guide_screen.dart';

void main() {
  testWidgets('shows all three tunnel walkthroughs', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RemoteAccessGuideScreen())),
    );

    expect(find.text('Remote access guide'), findsWidgets);
    expect(find.text('Tailscale (recommended)'), findsOneWidget);
    expect(find.text('WireGuard'), findsOneWidget);
    expect(find.text('Cloudflare Tunnel'), findsOneWidget);
    expect(find.text('tailscale.com/download'), findsOneWidget);
    expect(find.text('wireguard.com/install'), findsOneWidget);
  });

  testWidgets('the full guide link opens the repository doc (PI-04)', (
    tester,
  ) async {
    final opened = <Uri>[];
    final container = ProviderContainer(
      overrides: [
        linkLauncherProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RemoteAccessGuideScreen()),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Read the full remote-access guide'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Read the full remote-access guide'));
    await tester.pump();

    expect(opened, [Uri.parse(remoteAccessDocUrl)]);
  });
}
