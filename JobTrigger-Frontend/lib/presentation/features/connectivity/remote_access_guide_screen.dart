import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../common_widgets/external_link.dart';
import '../../common_widgets/responsive_center.dart';

/// PI-04 / IMP-36: the full URL is in the repository docs; keeping it as a
/// constant here makes the guide's link easy to test and change in one place.
const remoteAccessDocUrl =
    'https://github.com/SithumRaigamage/JobTrigger/blob/main/docs/remote-access.md';

/// PI-04 / IMP-36: short in-app walkthroughs for the three ways to reach a
/// self-hosted server away from home. The full, copyable commands live in
/// `docs/remote-access.md`, linked from the bottom of this screen.
class RemoteAccessGuideScreen extends ConsumerWidget {
  const RemoteAccessGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote access guide'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'A private address works on the same Wi-Fi as the computer '
                  'running Jenkins. To use the app on mobile data, pick one '
                  'private tunnel below. Keep the computer awake and the '
                  'services running.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _GuideCard(
                  title: 'Tailscale (recommended)',
                  icon: Icons.vpn_key_rounded,
                  summary:
                      'A private VPN between your phone and your computer. '
                      'Nothing is exposed to the internet.',
                  steps: const [
                    'Install Tailscale on the computer and sign in.',
                    'Install Tailscale on the phone with the same account and '
                        'switch it on.',
                    'Copy the computer’s 100.x.y.z address (tailscale ip -4).',
                    'Use that address as the backend host when rebuilding the '
                        'app, and as the Jenkins URL in Settings.',
                    'Keep Tailscale on whenever you use the app away from home.',
                  ],
                  linkLabel: 'tailscale.com/download',
                  link: Uri.parse('https://tailscale.com/download'),
                ),
                _GuideCard(
                  title: 'WireGuard',
                  icon: Icons.lock_rounded,
                  summary:
                      'A lightweight private VPN you run yourself. Good '
                      'when you want to own the server.',
                  steps: const [
                    'Install WireGuard on the computer and the phone.',
                    'Generate a key pair for each device on your WireGuard '
                        'server (a Raspberry Pi or the computer itself works).',
                    'Add the computer as a peer and allow its LAN address to '
                        'the phone’s public key.',
                    'Import the phone’s tunnel config in the WireGuard app and '
                        'activate it.',
                    'Set the app’s backend host and Jenkins URL to the '
                        'computer’s VPN address.',
                  ],
                  linkLabel: 'wireguard.com/install',
                  link: Uri.parse('https://www.wireguard.com/install/'),
                ),
                _GuideCard(
                  title: 'Cloudflare Tunnel',
                  icon: Icons.cloud_rounded,
                  summary:
                      'A public HTTPS address with no open ports. Fine '
                      'for a backend demo — do not expose Jenkins this way.',
                  steps: const [
                    'Sign in to Cloudflare and add a site to your account.',
                    'In Zero Trust → Networks → Tunnels, create a tunnel and '
                        'copy its token.',
                    'Install cloudflared on the computer and run the install '
                        'command Cloudflare shows with that token.',
                    'Add a public hostname pointing at http://localhost:5001 '
                        'for the backend.',
                    'Rebuild the app with BACKEND_BASE_URL set to the '
                        'https:// address Cloudflare gave you.',
                  ],
                  linkLabel: 'Cloudflare Tunnel docs',
                  link: Uri.parse(
                    'https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/',
                  ),
                ),
                const SizedBox(height: 4),
                ListTile(
                  minTileHeight: 56,
                  leading: const Icon(Icons.menu_book_rounded),
                  title: const Text('Read the full remote-access guide'),
                  subtitle: const Text('Commands, security notes and fixes'),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                  onTap: () =>
                      openExternalLink(ref, Uri.parse(remoteAccessDocUrl)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideCard extends ConsumerWidget {
  const _GuideCard({
    required this.title,
    required this.icon,
    required this.summary,
    required this.steps,
    required this.linkLabel,
    required this.link,
  });

  final String title;
  final IconData icon;
  final String summary;
  final List<String> steps;
  final String linkLabel;
  final Uri link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: t.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(summary, style: textTheme.bodyMedium),
              const SizedBox(height: 8),
              for (final (index, step) in steps.indexed)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${index + 1}.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: Text(step, style: textTheme.bodyMedium)),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => openExternalLink(ref, link),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(linkLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
