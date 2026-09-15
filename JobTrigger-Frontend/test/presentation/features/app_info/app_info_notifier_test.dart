import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/app_info_repository_impl.dart';
import 'package:job_trigger/domain/app_info/app_info.dart';
import 'package:job_trigger/domain/app_info/app_info_repository.dart';
import 'package:job_trigger/presentation/features/app_info/app_info_notifier.dart';

class _FakeAppInfoRepository implements AppInfoRepository {
  Result<AppInfo, AppFailure> fetchAppInfoResult = const Ok(
    AppInfo(appVersion: '1.0.0', buildNumber: '1'),
  );
  int fetchAppInfoCallCount = 0;

  @override
  Future<Result<AppInfo, AppFailure>> fetchAppInfo() async {
    fetchAppInfoCallCount++;
    return fetchAppInfoResult;
  }
}

void main() {
  test('fetches and exposes the app info on success', () async {
    final repo = _FakeAppInfoRepository()
      ..fetchAppInfoResult = const Ok(
        AppInfo(
          appVersion: '2.3.1',
          buildNumber: '42',
          supportEmail: 'support@jobtrigger.com',
        ),
      );
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [appInfoRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final info = await container.read(appInfoNotifierProvider.future);

    expect(info.appVersion, '2.3.1');
    expect(info.buildNumber, '42');
    expect(info.supportEmail, 'support@jobtrigger.com');
  });

  test('a repository failure surfaces as an AsyncError with the AppFailure', () async {
    final repo = _FakeAppInfoRepository()
      ..fetchAppInfoResult = const Err(NotFoundFailure());
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [appInfoRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(appInfoNotifierProvider, (_, _) {});

    await expectLater(
      container.read(appInfoNotifierProvider.future),
      throwsA(isA<NotFoundFailure>()),
    );

    final state = container.read(appInfoNotifierProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<NotFoundFailure>());
  });

  test('refresh() re-fetches the app info', () async {
    final repo = _FakeAppInfoRepository()
      ..fetchAppInfoResult = const Ok(
        AppInfo(appVersion: '1.0.0', buildNumber: '1'),
      );
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [appInfoRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(appInfoNotifierProvider, (_, _) {});
    await container.read(appInfoNotifierProvider.future);

    repo.fetchAppInfoResult = const Ok(
      AppInfo(appVersion: '1.1.0', buildNumber: '2'),
    );
    await container.read(appInfoNotifierProvider.notifier).refresh();
    final info = await container.read(appInfoNotifierProvider.future);

    expect(repo.fetchAppInfoCallCount, 2);
    expect(info.appVersion, '1.1.0');
  });
}
