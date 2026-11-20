import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../credential/jenkins_server.dart';

/// US-SUB-11 AC17: a Jenkins server the user's team owner shares with the
/// team. [server] is usable as the active server; its id carries
/// [idPrefix] so it never collides with the user's own credentials.
class TeamServer {
  const TeamServer({required this.server, this.sharedBy});

  static const idPrefix = 'team:';

  /// True for an active-server id that belongs to a team server.
  static bool isTeamId(String? id) => id != null && id.startsWith(idPrefix);

  final JenkinsServer server;

  /// The owner's email, shown as "Shared by …".
  final String? sharedBy;
}

/// US-SUB-11 AC17: reads the team's shared Jenkins servers. Read-only: they
/// are edited, shared and unshared on the website by the owner.
abstract class TeamServersRepository {
  /// Empty when the user is in no active team, or the backend has teams off.
  Future<Result<List<TeamServer>, AppFailure>> fetchShared();
}
