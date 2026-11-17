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

/// Runs a store write in turn with the caller's other writes (see
/// `BuildWatchNotifier`), so the pass's final load-and-save can't interleave
/// with an add or remove.
typedef SerializeWrite =
    Future<List<BuildWatch>> Function(Future<List<BuildWatch>> Function());

/// One pass over every watch: shared by the in-app timer and the background
/// task, so both behave identically. Returns the watches that remain.
///
/// The network calls take a while (up to the client timeouts per watch),
/// and the user may add or remove watches meanwhile, from this isolate or
/// the other one. So the pass only records an outcome per watch [key], and
/// at the end applies those outcomes to a *fresh* load of the store
/// (AUD-49): a watch added during the pass survives, a watch removed during
/// it stays removed, and only the watches this pass actually decided on
/// change.
Future<List<BuildWatch>> runWatchCheck({
  required BuildWatchStore store,
  required RepositoryForServer repositoryFor,
  required Future<void> Function(BuildNotification) notify,
  SerializeWrite? serialize,
}) async {
  final watches = await store.load();
  if (watches.isEmpty) return const [];

  // Key -> what to store instead (null: drop). Unlisted keys: untouched.
  final outcomes = <String, BuildWatch?>{};
  final repositories = <String, JenkinsRepository?>{};
  for (final watch in watches) {
    JenkinsRepository? repository;
    try {
      repository = repositories.containsKey(watch.serverId)
          ? repositories[watch.serverId]
          : repositories[watch.serverId] = await repositoryFor(watch.serverId);
    } on Object {
      continue; // Unreachable right now: leave it for later.
    }
    if (repository == null) {
      outcomes[watch.key] = null; // Credentials gone: drop.
      continue;
    }

    final history = await repository.fetchJobHistory(watch.jobUrl, count: 5);
    if (history case Ok(value: final recent)) {
      final outcome = decideWatch(watch, recent);
      if (outcome.notify case final notification?) await notify(notification);
      outcomes[watch.key] = outcome.keep;
    }
    // Err: transient, leave it untouched.
  }

  Future<List<BuildWatch>> commit() async {
    final merged = [
      for (final current in await store.load())
        if (!outcomes.containsKey(current.key))
          current
        else
          ?outcomes[current.key],
    ];
    await store.save(merged);
    return merged;
  }

  return serialize == null ? commit() : serialize(commit);
}
