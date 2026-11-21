import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/error_message.dart';
import '../../../core/platform/package_info_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../common_widgets/app_logo.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/external_link.dart';
import '../../common_widgets/grouped_card.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import 'app_info_notifier.dart';

/// Ported from `AppInfoView.swift`, laid out to the P14 design
/// (`UI-UX/screens/20-app-info`) — see `docs/state-management.md`'s
/// `AppInfoNotifier` entry. Links open externally (`openExternalLink`),
/// matching the old app's `openURL` environment action, plus a toast when
/// nothing can open them (AUD-22).
class AppInfoScreen extends ConsumerStatefulWidget {
  const AppInfoScreen({super.key});

  @override
  ConsumerState<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends ConsumerState<AppInfoScreen> {
  @override
  void initState() {
    super.initState();
    // US-PROF-03: opening the screen refreshes app info older than its TTL.
    // After the first frame: a provider can't change while widgets build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(appInfoNotifierProvider.notifier).refreshIfStale();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appInfoAsync = ref.watch(appInfoNotifierProvider);
    final installed = ref.watch(packageInfoProvider).value;
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ResponsiveCenter(
                // US-PROF-03: the header is local (the installed version
                // from package_info_plus), so it shows whatever the
                // backend does; only the backend's links wait or fail.
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  children: [
                    const Center(child: AppLogo(size: 76)),
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(
                        'JobTrigger',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (installed case final p?)
                      Text(
                        'Version ${p.version}',
                        key: const Key('app_info_version'),
                        textAlign: TextAlign.center,
                        style: AppTypography.mono(
                          textTheme.bodyMedium?.copyWith(color: t.textMuted),
                        ),
                      ),
                    const SizedBox(height: 28),
                    ...appInfoAsync.when(
                      data: (info) => [
                        GroupedCard(
                          children: [
                            // PI-04: the in-app walkthrough for reaching a
                            // self-hosted server away from home.
                            _remoteAccessRow(context),
                            // US-PROF-03: the website's changelog.
                            if (info.releaseNotesUrl case final url?)
                              _LinkRow(
                                title: 'Release notes',
                                icon: Icons.open_in_new_rounded,
                                onTap: () => _open(ref, url),
                              ),
                            if (info.privacyPolicyUrl case final url?)
                              _LinkRow(
                                title: 'Privacy policy',
                                icon: Icons.open_in_new_rounded,
                                onTap: () => _open(ref, url),
                              ),
                            if (info.termsOfServiceUrl case final url?)
                              _LinkRow(
                                title: 'Terms of service',
                                icon: Icons.open_in_new_rounded,
                                onTap: () => _open(ref, url),
                              ),
                            // The backend hands a URL, not an in-app page,
                            // so this opens out like the two above.
                            if (info.openSourceLicensesUrl case final url?)
                              _LinkRow(
                                title: 'Open-source licenses',
                                icon: Icons.open_in_new_rounded,
                                onTap: () => _open(ref, url),
                              ),
                            if (info.supportEmail != null)
                              _LinkRow(
                                title: 'Contact support',
                                subtitle: info.supportEmail,
                                icon: Icons.mail_outline_rounded,
                                // P25-05: a ticket we can track, with the
                                // address still offered on that screen.
                                onTap: () => context.push(AppRoutes.support),
                              ),
                          ],
                        ),
                      ],
                      loading: () => [
                        const Center(child: CircularProgressIndicator()),
                      ],
                      // Non-blocking: the version above and the local guide
                      // stay usable; only the backend's links are missing.
                      error: (error, stackTrace) => [
                        GroupedCard(children: [_remoteAccessRow(context)]),
                        const SizedBox(height: 16),
                        ConnectionErrorView(
                          message: describeError(error),
                          onRetry: () => ref
                              .read(appInfoNotifierProvider.notifier)
                              .refresh(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Jenkins and GitHub calls go straight from this '
                      'device to your servers.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _remoteAccessRow(BuildContext context) => _LinkRow(
    title: 'Remote access guide',
    subtitle: 'Use Jenkins on mobile data',
    icon: Icons.vpn_key_outlined,
    onTap: () => context.push(AppRoutes.remoteAccessGuide),
  );

  Future<void> _open(WidgetRef ref, String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null) return;
    await openExternalLink(ref, uri);
  }
}

/// A row that leaves the app; its trailing icon says where it goes.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return ListTile(
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Icon(icon, size: 20, color: t.textMuted),
      onTap: onTap,
    );
  }
}
