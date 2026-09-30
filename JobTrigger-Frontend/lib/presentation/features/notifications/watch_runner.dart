import '../../../core/error/result.dart';
import '../../../data/cache/build_watch_store.dart';
import '../../../domain/jenkins/build_watch.dart';
import '../../../domain/jenkins/jenkins_repository.dart';

/// A server's repository for a watch check. Returns null when that server's
/// credentials are gone (logged out, server deleted), which drops its
/// watches silently (US-JX-10). Throws when they can't be *reached* right
/// now, which keeps the watches for next time.
typedef RepositoryForServer =
    Future<JenkinsRepository?> Function(String serverId);

/// One pass over every watch: shared by the in-app timer and the background
/// task, so both behave identically. Returns the watches that remain.
Future<List<BuildWatch>> runWatchCheck({
  required BuildWatchStore store,
  required RepositoryForServer repositoryFor,
  required Future<void> Function(BuildNotification) notify,
}) async {
  final watches = await store.load();
  if (watches.isEmpty) return const [];

  final remaining = <BuildWatch>[];
  final repositories = <String, JenkinsRepository?>{};
  for (final watch in watches) {
    JenkinsRepository? repository;
    try {
      repository = repositories.containsKey(watch.serverId)
          ? repositories[watch.serverId]
          : repositories[watch.serverId] = await repositoryFor(watch.serverId);
    } on Object {
      remaining.add(watch); // Unreachable right now: try again later.
      continue;
    }
    if (repository == null) continue; // Credentials gone: drop.

    final history = await repository.fetchJobHistory(watch.jobUrl, count: 5);
    switch (history) {
      case Ok(value: final recent):
        final outcome = decideWatch(watch, recent);
        if (outcome.notify case final notification?) await notify(notification);
        if (outcome.keep case final kept?) remaining.add(kept);
      case Err():
        remaining.add(watch); // Transient: keep it.
    }
  }
  await store.save(remaining);
  return remaining;
}
