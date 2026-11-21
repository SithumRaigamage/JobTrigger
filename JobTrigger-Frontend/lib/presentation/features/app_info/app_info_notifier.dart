import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/app_info_repository_impl.dart';
import '../../../domain/app_info/app_info.dart';

part 'app_info_notifier.g.dart';

/// See `docs/state-management.md`'s `AppInfoNotifier` entry — cached
/// version/build/legal-link info from `GET /api/appinfo`. Follows the
/// standard shape from `docs/architecture.md §4`.
///
/// US-PROF-03 "cached with a short TTL": kept for the session (the update
/// gate reads it too), and fetched again by [refreshIfStale] once it is
/// older than [ttl]. No timer: nothing is left running when nobody looks.
@riverpod
class AppInfoNotifier extends _$AppInfoNotifier {
  static const ttl = Duration(minutes: 10);

  DateTime? _fetchedAt;

  @override
  Future<AppInfo> build() async {
    ref.keepAlive();
    final result = await ref.watch(appInfoRepositoryProvider).fetchAppInfo();
    _fetchedAt = now();
    return result.fold((info) => info, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();

  /// Fetches again when the last answer is older than [ttl].
  void refreshIfStale() {
    final fetchedAt = _fetchedAt;
    if (fetchedAt != null && now().difference(fetchedAt) > ttl) {
      ref.invalidateSelf();
    }
  }

  /// The current time; tests override it.
  @protected
  DateTime now() => DateTime.now();
}
