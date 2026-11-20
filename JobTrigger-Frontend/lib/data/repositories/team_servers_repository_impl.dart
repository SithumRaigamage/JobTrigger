import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/credential/jenkins_server.dart';
import '../../domain/team/team_server.dart';
import '../credentials/credential_secrets.dart';
import '../demo/demo_mode_notifier.dart';

part 'team_servers_repository_impl.g.dart';

/// US-SUB-11 AC17: `GET /api/team/servers` lists the shared servers masked;
/// each secret comes from `GET /api/team/servers/jenkins/:id/secret`
/// through [CredentialSecrets], cached in secure storage under its own
/// tool key, like the user's own secrets (E4). Nothing is copied into the
/// user's credentials: unsharing on the website ends access at once.
class TeamServersRepositoryImpl implements TeamServersRepository {
  TeamServersRepositoryImpl(this._dio, this._secrets);

  final Dio _dio;
  final CredentialSecrets _secrets;

  static const _path = '/api/team/servers';
  static const _secretPath = '/api/team/servers/jenkins';
  static const _tool = 'team-jenkins';

  @override
  Future<Result<List<TeamServer>, AppFailure>> fetchShared() =>
      guardRequest(() async {
        // Untyped: a 404's body is an object, and the status decides first.
        final response = await _dio.get<Object?>(
          _path,
          // A 404 is a backend with teams off: no team servers, not an error.
          options: Options(
            validateStatus: (status) =>
                status != null && (status < 400 || status == 404),
          ),
        );
        if (response.statusCode == 404) return const <TeamServer>[];
        final rows = (response.data as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
        return Future.wait(rows.map(_toTeamServer));
      });

  Future<TeamServer> _toTeamServer(Map<String, dynamic> json) async {
    final id = json['id'] as String;
    final needsReentry = json['needsReentry'] == true;
    final secret = needsReentry
        ? null
        : await _secrets.resolve(
            tool: _tool,
            path: _secretPath,
            id: id,
            listedVersion: json['updatedAt'] as String?,
            primaryField: 'password',
            extraField: 'paramToken',
          );
    return TeamServer(
      server: JenkinsServer(
        id: '${TeamServer.idPrefix}$id',
        serverName: json['serverName'] as String,
        jenkinsURL: json['jenkinsURL'] as String,
        username: json['username'] as String,
        secret: secret?.primary,
        paramToken: secret?.extra,
        needsReentry: needsReentry,
      ),
      sharedBy: json['sharedBy'] as String?,
    );
  }
}

class _NoTeamServers implements TeamServersRepository {
  const _NoTeamServers();

  @override
  Future<Result<List<TeamServer>, AppFailure>> fetchShared() async =>
      const Ok([]);
}

@riverpod
TeamServersRepository teamServersRepository(Ref ref) {
  // E2: demo mode never reaches the backend, and has no team.
  if (ref.watch(demoModeNotifierProvider)) return const _NoTeamServers();
  return TeamServersRepositoryImpl(
    ref.watch(dioBackendProvider),
    CredentialSecrets(
      ref.watch(dioBackendProvider),
      ref.watch(secureStorageProvider),
    ),
  );
}
