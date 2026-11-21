/// US-JX-16: where "Replay with edits" gets its starting script.
///
/// Jenkins only shows a *build's* original script inside the `replay/` HTML
/// page, which the app does not scrape (P11-27). The job's `config.xml`
/// holds the script of an inline ("Pipeline script") job, so that is the
/// documented source; a Jenkinsfile from SCM has no script there.
sealed class ReplayScript {
  const ReplayScript();
}

/// An inline pipeline: its current script, and whether it runs in the
/// Groovy sandbox.
final class InlineReplayScript extends ReplayScript {
  const InlineReplayScript({required this.script, required this.sandbox});

  final String script;
  final bool sandbox;
}

/// A pipeline whose Jenkinsfile comes from a repository: not replayable
/// with edits from the app.
final class ScmReplayScript extends ReplayScript {
  const ScmReplayScript();
}

/// A job whose `config.xml` has no pipeline definition at all.
final class NoReplayScript extends ReplayScript {
  const NoReplayScript();
}

/// The cause text Jenkins writes on a replayed build: "Replayed #41".
String replayedCause(int originalNumber) => 'Replayed #$originalNumber';

/// True when [causes] say the build was itself a replay.
bool wasReplayed(List<String> causes) =>
    causes.any((cause) => cause.startsWith('Replayed #'));
