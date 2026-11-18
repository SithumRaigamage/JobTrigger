import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/credentials/github_credentials_notifier.dart';
import '../../data/credentials/sonarqube_credentials_notifier.dart';
import '../../data/credentials/credentials_notifier.dart';
import '../../domain/credential/github_credential.dart';
import '../../domain/credential/sonarqube_credential.dart';
import '../../domain/credential/jenkins_server.dart';
import '../navigation/app_routes.dart';

/// Shared header for any tool screen that shows which server/credential is
/// active and lets the user switch to another one inline, without leaving the
/// screen. Mirrors the Home/Overview screens' chip pattern so every screen in
/// a tool reads the same (`UI-UX/screens/05`).
///
/// Usage per tool:
///   SonarQube: [SonarQubeCredentialHeader]  → onSwitch = setActiveCredential
///   GitHub:    [GitHubCredentialHeader]     → onSwitch = setActiveCredential
///   Jenkins:   [JenkinsServerHeader]        → onSwitch = setActiveServer
///
/// Each header is a single tappable chip that drops a PopupMenu with the
/// saved credentials/servers, a check on the active one, and a "Manage …"
/// item that opens Settings. It does NOT own the active state — the caller
/// passes the current value and the switch callback. It carries no section
/// title (each screen keeps its own heading) and accepts optional [actions]
/// for the icons that belong on the same line, so it drops into the top of a
/// root screen or under the back button of a drill-down.
class _SelectorChip<T> extends StatelessWidget {
  const _SelectorChip({
    required this.label,
    required this.activeId,
    required this.items,
    required this.onSwitch,
    required this.onManage,
    required this.manageLabel,
    required this.icon,
    required this.semanticsLabel,
  });

  final String label;
  final String activeId;
  final List<_SelectorItem<T>> items;
  final ValueChanged<T> onSwitch;
  final VoidCallback onManage;
  final String manageLabel;
  final IconData icon;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final cs = theme.colorScheme;
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
        ),
        child: PopupMenuButton<String>(
          position: PopupMenuPosition.under,
          borderRadius: BorderRadius.circular(22),
          onSelected: (id) {
            if (id == _manageAction) {
              onManage();
              return;
            }
            if (id == activeId) return;
            for (final item in items) {
              if (item.id == id) {
                onSwitch(item.value);
                return;
              }
            }
          },
          itemBuilder: (context) => [
            for (final item in items)
              PopupMenuItem<String>(
                value: item.id,
                child: Row(
                  children: [
                    if (item.id == activeId)
                      Icon(Icons.check_rounded, size: 18, color: cs.primary)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.label),
                          if (item.subtitle != null)
                            Text(
                              item.subtitle!,
                              style: t.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: _manageAction,
              child: ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(manageLabel),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelMedium,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorItem<T> {
  const _SelectorItem({
    required this.id,
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String id;
  final String label;
  final T value;
  final String? subtitle;
}

/// Sentinel returned by "Manage …" — opens Settings instead of switching.
const _manageAction = '__manage__';

/// One line at the top of a tool screen: the active credential/server chip on
/// the left, then any [actions] the screen keeps there.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.chip, this.actions = const <Widget>[]});

  final Widget chip;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          // The chip keeps its natural width (and ellipsizes only when the
          // label really is wider than the row) while the actions stay
          // pinned right. `Flexible` + `Spacer` would split the free space
          // in half and truncate a long server name early.
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: chip),
          ),
          for (final action in actions) action,
        ],
      ),
    );
  }
}

/// De-duplicates by id, keeping the first (the active one) first.
List<_SelectorItem<T>> _merge<T>(
  T active,
  String Function(T) idOf,
  String Function(T) labelOf,
  String? Function(T) subtitleOf,
  List<T>? saved,
) {
  final items = <_SelectorItem<T>>[];
  final seen = <String>{};
  for (final value in [active, ...?saved]) {
    final id = idOf(value);
    if (!seen.add(id)) continue;
    items.add(
      _SelectorItem<T>(
        id: id,
        label: labelOf(value),
        value: value,
        subtitle: subtitleOf(value),
      ),
    );
  }
  return items;
}

/// SonarQube screen header: shows the active credential and lets the user
/// switch inline.
class SonarQubeCredentialHeader extends ConsumerWidget {
  const SonarQubeCredentialHeader({
    super.key,
    required this.credential,
    required this.onSwitch,
    this.actions = const <Widget>[],
  });

  final SonarQubeCredential credential;
  final ValueChanged<SonarQubeCredential> onSwitch;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(sonarQubeCredentialsNotifierProvider).value;
    final items = _merge<SonarQubeCredential>(
      credential,
      (c) => c.id,
      (c) => c.label,
      (c) => c.baseUrl,
      saved,
    );
    return _HeaderRow(
      actions: actions,
      chip: _SelectorChip<SonarQubeCredential>(
        icon: Icons.cloud_outlined,
        label: credential.label,
        activeId: credential.id,
        items: items,
        onSwitch: onSwitch,
        semanticsLabel: 'SonarQube ${credential.label}. Switch credential',
        manageLabel: 'Manage credentials…',
        onManage: () => context.go(AppRoutes.settings),
      ),
    );
  }
}

/// GitHub screen header: shows the active credential and lets the user
/// switch inline.
class GitHubCredentialHeader extends ConsumerWidget {
  const GitHubCredentialHeader({
    super.key,
    required this.credential,
    required this.onSwitch,
    this.actions = const <Widget>[],
  });

  final GitHubCredential credential;
  final ValueChanged<GitHubCredential> onSwitch;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(gitHubCredentialsNotifierProvider).value;
    final items = _merge<GitHubCredential>(
      credential,
      (c) => c.id,
      (c) => c.label,
      (c) => null,
      saved,
    );
    return _HeaderRow(
      actions: actions,
      chip: _SelectorChip<GitHubCredential>(
        icon: Icons.vpn_key_outlined,
        label: credential.label,
        activeId: credential.id,
        items: items,
        onSwitch: onSwitch,
        semanticsLabel: 'GitHub ${credential.label}. Switch credential',
        manageLabel: 'Manage credentials…',
        onManage: () => context.go(AppRoutes.settings),
      ),
    );
  }
}

/// Jenkins screen header: shows the active server and lets the user switch
/// inline.
class JenkinsServerHeader extends ConsumerWidget {
  const JenkinsServerHeader({
    super.key,
    required this.server,
    required this.onSwitch,
    this.actions = const <Widget>[],
  });

  final JenkinsServer server;
  final ValueChanged<JenkinsServer> onSwitch;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(credentialsNotifierProvider).value;
    final items = _merge<JenkinsServer>(
      server,
      (s) => s.id,
      (s) => s.serverName,
      (s) => s.jenkinsURL,
      saved,
    );
    return _HeaderRow(
      actions: actions,
      chip: _SelectorChip<JenkinsServer>(
        icon: Icons.dns_outlined,
        label: server.serverName,
        activeId: server.id,
        items: items,
        onSwitch: onSwitch,
        semanticsLabel: 'Jenkins ${server.serverName}. Switch server',
        manageLabel: 'Manage servers…',
        onManage: () => context.go(AppRoutes.settings),
      ),
    );
  }
}
