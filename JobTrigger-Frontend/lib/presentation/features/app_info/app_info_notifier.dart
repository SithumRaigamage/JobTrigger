import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/app_info_repository_impl.dart';
import '../../../domain/app_info/app_info.dart';

part 'app_info_notifier.g.dart';

/// See `docs/state-management.md`'s `AppInfoNotifier` entry — cached
/// version/build/legal-link info from `GET /api/appinfo`. Follows the
/// standard shape from `docs/architecture.md §4`.
@riverpod
class AppInfoNotifier extends _$AppInfoNotifier {
  @override
  Future<AppInfo> build() async {
    final result = await ref.watch(appInfoRepositoryProvider).fetchAppInfo();
    return result.fold((info) => info, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
