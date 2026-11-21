import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/package_info_provider.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/app_info_repository_impl.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';
import 'package:job_trigger/domain/app_info/app_info_repository.dart';
import 'package:job_trigger/presentation/features/app_info/app_info_notifier.dart';
import 'package:job_trigger/presentation/features/app_info/update_gate.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// US-PROF-03 "Forced update gate": an app older than the backend's
/// `minSupportedVersion` is covered by an "Update required" screen.
class _Repo implements AppInfoRepository {
  _Repo(this.result);

  final Result<AppInfo, AppFailure> result;
  int calls = 0;

  @override
  Future<Result<AppInfo, AppFailure>> fetchAppInfo() async {
    calls++;
    return result;
  }
}

Future<void> _pump(
  WidgetTester tester,
  Result<AppInfo, AppFailure> result, {
  String installed = '1.0.0',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        appInfoRepositoryProvider.overrideWithValue(_Repo(result)),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'JobTrigger',
            packageName: 'app',
            version: installed,
            buildNumber: '7',
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const UpdateRequiredGate(child: Text('the app')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppInfo _info(String? min) =>
    AppInfo(appVersion: '1.0.0', buildNumber: '7', minSupportedVersion: min);

void main() {
  group('isUpdateRequired', () {
    test('older than the minimum needs an update', () {
      expect(isUpdateRequired('1.0.0', '1.0.1'), isTrue);
      expect(isUpdateRequired('1.9.9', '2.0.0'), isTrue);
      expect(isUpdateRequired('1.0.9', '1.1.0'), isTrue);
    });

    test('the same or newer version is fine', () {
      expect(isUpdateRequired('1.0.1', '1.0.1'), isFalse);
      expect(isUpdateRequired('1.2.0', '1.0.1'), isFalse);
      expect(isUpdateRequired('10.0.0', '9.9.9'), isFalse);
    });

    test('no minimum, or anything unparseable, blocks nobody', () {
      expect(isUpdateRequired('1.0.0', null), isFalse);
      expect(isUpdateRequired('1.0.0', 'one'), isFalse);
      expect(isUpdateRequired('dev', '1.0.1'), isFalse);
    });
  });

  testWidgets('an unsupported version shows Update required, not the app', (
    tester,
  ) async {
    await _pump(tester, Ok(_info('1.0.1')));

    expect(find.byKey(const Key('update_required')), findsOneWidget);
    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('the app'), findsNothing);
  });

  testWidgets('a supported version shows the app', (tester) async {
    await _pump(tester, Ok(_info('1.0.0')));

    expect(find.text('the app'), findsOneWidget);
    expect(find.text('Update required'), findsNothing);
  });

  testWidgets('no minimum set shows the app', (tester) async {
    await _pump(tester, Ok(_info(null)));

    expect(find.text('the app'), findsOneWidget);
  });

  testWidgets('a failed app info fetch never blocks the app', (tester) async {
    await _pump(tester, const Err(NetworkFailure()));

    expect(find.text('the app'), findsOneWidget);
    expect(find.text('Update required'), findsNothing);
  });

  // "cached with a short TTL": App Info and the gate share one fetch,
  // kept after the last listener goes away.
  test('app info is fetched once and kept after its screen closes', () async {
    final repo = _Repo(Ok(_info(null)));
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [appInfoRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final sub = container.listen(appInfoNotifierProvider, (_, _) {});
    await container.read(appInfoNotifierProvider.future);
    sub.close();
    await Future<void>.delayed(Duration.zero);
    await container.read(appInfoNotifierProvider.future);

    expect(repo.calls, 1);
  });
}
