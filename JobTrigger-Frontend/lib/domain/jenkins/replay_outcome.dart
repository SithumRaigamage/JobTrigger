import '../../core/error/app_failure.dart';
import 'jenkins_build.dart';

// US-JX-16: plain domain types, kept out of the notifier's file so code
// generation never has to inspect them (a freezed pass on them hung).

/// What a submitted replay led to.
sealed class ReplayOutcome {
  const ReplayOutcome();
}

/// AC8: the new build was found.
final class ReplayedBuild extends ReplayOutcome {
  const ReplayedBuild(this.build);
  final JenkinsBuild build;
}

/// AC8: Jenkins accepted it, the build isn't listed yet.
final class ReplayStarted extends ReplayOutcome {
  const ReplayStarted();
}

/// AC5: refused; [failure] says why.
final class ReplayRefused extends ReplayOutcome {
  const ReplayRefused(this.failure);
  final AppFailure failure;
}
