import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/credential/jenkins_server.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/jenkins_link.dart';
import '../../common_widgets/confirmation_dialog.dart';
import '../../common_widgets/glass_surface.dart';
import '../../navigation/app_routes.dart';
import '../settings/active_server_notifier.dart';
import '../settings/credentials_notifier.dart';

/// US-JX-19: opens a Jenkins URL (from `jobtrigger://app/open?url=…` or the
/// "Open Jenkins link" action) on the matching job, build, or console.
///
/// Only saved servers are ever contacted: a link can't point the app at a
/// new host, and a URL carrying credentials is refused. If the link belongs
/// to a saved server that isn't active, the user confirms the switch.
class OpenLinkScreen extends ConsumerStatefulWidget {
  const OpenLinkScreen({super.key, required this.link});

  final String link;

  @override
  ConsumerState<OpenLinkScreen> createState() => _OpenLinkScreenState();
}

class _OpenLinkScreenState extends ConsumerState<OpenLinkScreen> {
  String? _problem;

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
    final resolved = resolveJenkinsLink(widget.link, servers);
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
      final confirmed = await showConfirmationDialog(
        context,
        title: 'Switch to ${resolved.server.serverName}?',
        message:
            'This link is on ${resolved.server.serverName}, not the active '
            'server.',
        confirmLabel: 'Switch',
      );
      if (!mounted) return;
      if (!confirmed) {
        context.go(AppRoutes.home);
        return;
      }
      await ref
          .read(activeServerNotifierProvider.notifier)
          .setActiveServer(resolved.server);
      if (!mounted) return;
    }

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
    return Scaffold(
      appBar: const GlassAppBar(title: Text('Open link')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: problem == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link_off, size: 40),
                    const SizedBox(height: 12),
                    Text(problem, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: const Text('Go to jobs'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
