import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_hotspot.dart';

part 'sonarqube_hotspots_notifier.g.dart';

/// What the hotspot list holds and where "Load more" continues from.
class SonarQubeHotspotsState {
  const SonarQubeHotspotsState({
    required this.hotspots,
    required this.total,
    this.loadingMore = false,
  });

  final List<SonarQubeHotspot> hotspots;

  /// How many the server says exist under this filter.
  final int total;
  final bool loadingMore;

  bool get hasMore => hotspots.length < total;
}

/// A project's security hotspots (`US-SQ-HOTSPOT-01`), to review or already
/// reviewed. Read-only: reviewing is `US-SQ-WRITE-04`.
@riverpod
class SonarQubeHotspotsNotifier extends _$SonarQubeHotspotsNotifier {
  late final String _projectKey;

  @override
  Future<SonarQubeHotspotsState> build(String projectKey) {
    _projectKey = projectKey;
    return _fetch(1, reviewed: false);
  }

  Future<SonarQubeHotspotsState> _fetch(
    int page, {
    required bool reviewed,
  }) async {
    final result = await ref
        .read(sonarQubeRepositoryProvider)
        .fetchHotspots(_projectKey, reviewed: reviewed, page: page);
    return result.fold(
      (page) =>
          SonarQubeHotspotsState(hotspots: page.hotspots, total: page.total),
      (failure) => throw failure,
    );
  }

  /// Switches between the ones to review and the reviewed ones.
  Future<void> setReviewed({required bool reviewed}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(1, reviewed: reviewed));
  }

  Future<void> loadMore({required bool reviewed}) async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      SonarQubeHotspotsState(
        hotspots: current.hotspots,
        total: current.total,
        loadingMore: true,
      ),
    );
    final page = current.hotspots.length ~/ sonarQubeHotspotsPageSize + 1;
    final next = await AsyncValue.guard(() => _fetch(page, reviewed: reviewed));
    if (next.value == null) {
      state = AsyncData(current);
      return;
    }
    state = AsyncData(
      SonarQubeHotspotsState(
        hotspots: [...current.hotspots, ...next.value!.hotspots],
        total: next.value!.total,
      ),
    );
  }

  Future<void> refresh() async {
    const stillReviewed = false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(1, reviewed: stillReviewed));
  }
}

/// One hotspot's rule name and code (`api/hotspots/show`), loaded when its
/// row is expanded.
@riverpod
Future<SonarQubeHotspotDetail> sonarQubeHotspotDetail(
  Ref ref,
  String hotspotKey,
) async {
  final result = await ref
      .watch(sonarQubeRepositoryProvider)
      .fetchHotspotDetail(hotspotKey);
  return result.fold((detail) => detail, (failure) => throw failure);
}
