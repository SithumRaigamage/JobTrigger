import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/credential/jenkins_server.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/jenkins_link.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/credential/server_url.dart';
import '../../common_widgets/grouped_card.dart';
import '../../common_widgets/inline_alert.dart';
import '../../common_widgets/pinned_footer_layout.dart';
import '../../navigation/app_routes.dart';
import '../../../data/credentials/active_server_notifier.dart';
import '../../../data/credentials/credentials_notifier.dart';

/// US-JX-19: opens a Jenkins URL (from `jobtrigger://app/open?url=…`) on the
/// matching job, build, or console.
///
/// Only saved servers are ever contacted: a link can't point the app at a
/// new host, and a URL carrying credentials is refused. If the link belongs
/// to a saved server that isn't active, the user confirms the switch.
class OpenLinkScreen extends ConsumerStatefulWidget {
  const OpenLinkScreen({super.key, required this.link, this.serverId});

  final String link;

  /// The saved server the link came from, when known (a build
  /// notification, AUD-45). Preferred when it matches the link.
  final String? serverId;

  @override
  ConsumerState<OpenLinkScreen> createState() => _OpenLinkScreenState();
}

class _OpenLinkScreenState extends ConsumerState<OpenLinkScreen> {
  String? _problem;

  /// A link on a saved server that isn't the active one, waiting for the
  /// user to confirm the switch (AUD-45).
  JenkinsLinkTarget? _pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    final List<JenkinsServer> servers;
    try {
      servers = await ref.read(credentialsNotifierProvider.future);
    } on Object {
      return _fail("Couldn't load your saved servers. Try again.");
    }
    final resolved = resolveJenkinsLink(
      widget.link,
      servers,
      preferServerId: widget.serverId,
    );
    if (!mounted) return;
    if (resolved is! JenkinsLinkTarget) {
      return _fail(switch (resolved as JenkinsLinkProblem) {
        JenkinsLinkProblem.invalid => "That isn't a Jenkins link.",
        JenkinsLinkProblem.credentialsInUrl =>
          'That link contains a username and password, so it was not '
              'opened. Share links without credentials.',
        JenkinsLinkProblem.unknownServer =>
          'No saved server matches this link. Add the server in Settings '
              'first.',
        JenkinsLinkProblem.notAJob => "That link doesn't point to a job.",
      });
    }

    final active = ref.read(activeServerNotifierProvider);
    if (active?.id != resolved.server.id) {
      // Asked on this screen, not in a dialog over a spinner: what opens
      // and where it lives are the whole question (P14-20).
      setState(() => _pending = resolved);
      return;
    }
    _go(resolved);
  }

  Future<void> _switchAndOpen(JenkinsLinkTarget target) async {
    await ref
        .read(activeServerNotifierProvider.notifier)
        .setActiveServer(target.server);
    if (mounted) _go(target);
  }

  void _go(JenkinsLinkTarget resolved) {
    final job = JenkinsJob(name: resolved.jobLabel, url: resolved.jobUrl);
    final router = GoRouter.of(context)..go(AppRoutes.home);
    // Pushes return when the pushed route pops; nothing to await here.
    unawaited(router.push(AppRoutes.jobDetail, extra: job));
    if (resolved.buildUrl case final buildUrl?) {
      final build = JenkinsBuild(
        number: resolved.buildNumber!,
        url: buildUrl,
        timestamp: 0,
      );
      unawaited(
        router.push(
          resolved.showLog ? AppRoutes.buildLog : AppRoutes.buildDetail,
          extra: build,
        ),
      );
    }
  }

  void _fail(String message) {
    if (mounted) setState(() => _problem = message);
  }

  @override
  Widget build(BuildContext context) {
    final problem = _problem;
    final pending = _pending;
    return Scaffold(
      body: SafeArea(
        child: problem != null
            ? _Problem(message: problem)
            : pending != null
            ? _ConfirmSwitch(
                target: pending,
                current: ref.watch(activeServerNotifierProvider),
                onSwitch: () => _switchAndOpen(pending),
                onStay: () => context.go(AppRoutes.home),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

/// The link icon on a card tile, heading this screen's two states.
class _LinkMark extends StatelessWidget {
  const _LinkMark({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.cardBorder),
        ),
        child: Icon(icon, size: 26, color: t.running.foreground),
      ),
    );
  }
}

/// `UI-UX/screens/19-open-link`: what the link opens, which server it
/// moves to, and a warning when that server is reached over plain http.
class _ConfirmSwitch extends StatelessWidget {
  const _ConfirmSwitch({
    required this.target,
    required this.current,
    required this.onSwitch,
    required this.onStay,
  });

  final JenkinsLinkTarget target;
  final JenkinsServer? current;
  final VoidCallback onSwitch;
  final VoidCallback onStay;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    final to = target.server.serverName;
    final from = current?.serverName;
    final opens = [
      target.jobLabel,
      if (target.buildNumber case final number?) '#$number',
      if (target.showLog) 'console',
    ].join(' ');
    final label = textTheme.labelSmall?.copyWith(fontSize: 12);
    return PinnedFooterLayout(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: _LinkMark(icon: Icons.link_rounded),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text('Switch to $to?', style: textTheme.headlineSmall),
          ),
          const SizedBox(height: 8),
          Text(
            'This link is on $to'
            '${from == null ? '' : ', not $from'}. Opening it switches '
            'your active server; you can switch back in Settings.',
            style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: 24),
          GroupedCard(
            padding: const EdgeInsets.all(16),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Opens', style: label),
                  const SizedBox(height: 4),
                  Text(opens, style: AppTypography.mono(textTheme.bodyMedium)),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (from != null) ...[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From', style: label),
                              const SizedBox(height: 4),
                              Text(from, style: textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: t.textMuted,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('To', style: label),
                            const SizedBox(height: 4),
                            Text(to, style: textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isCleartextUrl(target.server.jenkinsURL)) ...[
                    const SizedBox(height: 14),
                    InlineAlert(
                      tone: StatusTone.unstable,
                      icon: Icons.warning_amber_rounded,
                      message:
                          '$to uses http://, so its traffic isn’t encrypted.',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: onSwitch,
            child: const Text('Switch and open'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
            onPressed: onStay,
            child: Text(from == null ? 'Not now' : 'Stay on $from'),
          ),
        ],
      ),
    );
  }
}

/// A link that can't be opened, and why.
class _Problem extends StatelessWidget {
  const _Problem({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PinnedFooterLayout(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: _LinkMark(icon: Icons.link_off_rounded),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text("Can't open this link", style: textTheme.headlineSmall),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: AppTokens.of(context).textMuted,
            ),
          ),
        ],
      ),
      footer: FilledButton(
        onPressed: () => context.go(AppRoutes.home),
        child: const Text('Go to jobs'),
      ),
    );
  }
}
