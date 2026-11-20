import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/no_retry.dart';
import '../../core/error/result.dart';
import '../../domain/team/team_server.dart';
import '../repositories/team_servers_repository_impl.dart';

part 'team_servers_notifier.g.dart';

/// US-SUB-11 AC17: the team's shared Jenkins servers, for Settings and for
/// `ActiveServerNotifier` (which restores an active team server on restart
/// and falls back when it stops being shared).
@Riverpod(retry: noRetry)
class TeamServersNotifier extends _$TeamServersNotifier {
  @override
  Future<List<TeamServer>> build() async {
    final result = await ref.watch(teamServersRepositoryProvider).fetchShared();
    return result.fold((servers) => servers, (failure) => throw failure);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
