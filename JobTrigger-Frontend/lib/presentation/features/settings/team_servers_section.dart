import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../data/credentials/active_server_notifier.dart';
import '../../../data/credentials/team_servers_notifier.dart';
import '../../../domain/team/team_server.dart';
import '../../common_widgets/grouped_card.dart';
import '../subscription/entitlements_notifier.dart';

/// US-SUB-11 AC17: the team's shared Jenkins servers, under the user's own.
/// Shown only to members of an active team (from `GET /api/subscription`),
/// so nobody else makes the extra request. Read-only here: the owner shares
/// and unshares them on the website.
class TeamServersSection extends ConsumerWidget {
  const TeamServersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(entitlementsNotifierProvider).value?.status.team;
    if (team == null || !team.active) return const SizedBox.shrink();
    final shared = ref.watch(teamServersNotifierProvider);
    final activeId = ref.watch(activeServerNotifierProvider)?.id;
    final t = AppTokens.of(context);
    return Column(
      key: const Key('team_servers_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 16, 0, 4),
          child: GroupHeader(title: 'Team servers'),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Shared by ${team.name}. Only the team owner can change them.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
        ),
        shared.when(
          data: (servers) => servers.isEmpty
              ? Text(
                  'Your team hasn\'t shared any Jenkins servers yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : GroupedCard(
                  children: [
                    for (final server in servers)
                      _TeamServerTile(
                        teamServer: server,
                        isActive: server.server.id == activeId,
                      ),
                  ],
                ),
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => TextButton(
            onPressed: () =>
                ref.read(teamServersNotifierProvider.notifier).refresh(),
            child: const Text("Couldn't load team servers. Retry"),
          ),
        ),
      ],
    );
  }
}

class _TeamServerTile extends ConsumerWidget {
  const _TeamServerTile({required this.teamServer, required this.isActive});

  final TeamServer teamServer;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = teamServer.server;
    final usable = server.secret != null;
    return ListTile(
      leading: const Icon(Icons.groups_outlined),
      title: Text(server.serverName),
      subtitle: Text(
        [
          server.jenkinsURL,
          if (teamServer.sharedBy case final by?) 'Shared by $by',
          if (!usable) "The owner's token needs re-entering",
        ].join('\n'),
      ),
      isThreeLine: teamServer.sharedBy != null,
      trailing: isActive
          ? const Chip(label: Text('Active'))
          : TextButton(
              onPressed: usable
                  ? () => ref
                        .read(activeServerNotifierProvider.notifier)
                        .setActiveServer(server)
                  : null,
              child: Text('Use', semanticsLabel: 'Use ${server.serverName}'),
            ),
    );
  }
}
