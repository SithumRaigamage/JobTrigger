import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/presentation/common_widgets/data_freshness.dart';

/// PI-05 / IMP-38: the shared freshness record and the banner that reads it.
/// The notifier is a keyed family so independent screens never overwrite
/// each other's "Updated …" time.
void main() {
  group('DataFreshnessNotifier', () {
    test('starts empty and offline false', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(dataFreshnessNotifierProvider('a')),
          (savedAt: null, offline: false));
    });

    test('markLoaded records the time and clears offline', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final at = DateTime.now().subtract(const Duration(minutes: 2));
      c.read(dataFreshnessNotifierProvider('a').notifier).markLoaded(at);
      expect(c.read(dataFreshnessNotifierProvider('a')),
          (savedAt: at, offline: false));
    });

    test('markOffline records the saved time and sets offline', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final at = DateTime(2026, 1, 2, 3, 4);
      c.read(dataFreshnessNotifierProvider('a').notifier).markOffline(at);
      expect(c.read(dataFreshnessNotifierProvider('a')),
          (savedAt: at, offline: true));
    });

    test('keys are independent', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(dataFreshnessNotifierProvider('a').notifier).markLoaded();
      expect(c.read(dataFreshnessNotifierProvider('b')),
          (savedAt: null, offline: false));
    });
  });

  group('DataFreshnessBanner', () {
    Future<void> pumpBanner(
      WidgetTester tester,
      Widget banner, {
      ProviderContainer? container,
    }) async {
      final c = container ?? ProviderContainer();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(theme: AppTheme.dark(), home: Scaffold(body: banner)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders nothing before any data is recorded', (tester) async {
      await pumpBanner(
        tester,
        const DataFreshnessBanner(freshnessKey: 'home'),
      );
      expect(find.byType(DataFreshnessBanner), findsOneWidget);
      expect(find.textContaining('Updated'), findsNothing);
    });

    testWidgets('a live load says "Updated just now" with the update icon', (
      tester,
    ) async {
      await pumpBanner(
        tester,
        DataFreshnessBanner(savedAt: DateTime.now(), offline: false),
      );
      expect(find.text('Updated just now'), findsOneWidget);
      expect(find.byIcon(Icons.update_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsNothing);
    });

    testWidgets('an offline fallback names the saved time and uses the cloud-off icon', (
      tester,
    ) async {
      await pumpBanner(
        tester,
        DataFreshnessBanner(
          savedAt: DateTime(2026, 1, 2, 3, 4),
          offline: true,
        ),
      );
      expect(find.textContaining('Offline — showing data from 03:04'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('the SonarQube style keeps its long-standing copy', (tester) async {
      await pumpBanner(
        tester,
        DataFreshnessBanner(
          style: FreshnessStyle.sonarqube,
          savedAt: DateTime.now().subtract(const Duration(hours: 2)),
          offline: true,
        ),
      );
      expect(
        find.textContaining('can\'t reach the server'),
        findsOneWidget,
      );
      expect(find.textContaining('2h ago'), findsOneWidget);
    });

    testWidgets('showOffline false hides only the offline message', (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await pumpBanner(
        tester,
        const DataFreshnessBanner(
          freshnessKey: 'home',
          showOffline: false,
        ),
        container: c,
      );
      // An offline state that a more specific banner owns elsewhere.
      c.read(dataFreshnessNotifierProvider('home').notifier)
          .markOffline(DateTime.now());
      await tester.pumpAndSettle();
      expect(find.textContaining('Offline'), findsNothing);
      expect(find.textContaining('Updated'), findsNothing);
    });

    testWidgets('watching a key reflects a later load', (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await pumpBanner(
        tester,
        const DataFreshnessBanner(freshnessKey: 'home'),
        container: c,
      );
      expect(find.textContaining('Updated'), findsNothing);
      c.read(dataFreshnessNotifierProvider('home').notifier).markLoaded();
      await tester.pumpAndSettle();
      expect(find.text('Updated just now'), findsOneWidget);
    });
  });
}
