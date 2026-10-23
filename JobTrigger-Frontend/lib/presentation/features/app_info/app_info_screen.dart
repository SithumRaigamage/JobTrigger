import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../common_widgets/app_logo.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/external_link.dart';
import '../../common_widgets/grouped_card.dart';
import '../../common_widgets/responsive_center.dart';
import 'app_info_notifier.dart';

/// Ported from `AppInfoView.swift`, laid out to the P14 design
/// (`UI-UX/screens/20-app-info`) — see `docs/state-management.md`'s
/// `AppInfoNotifier` entry. Links open externally (`openExternalLink`),
/// matching the old app's `openURL` environment action, plus a toast when
/// nothing can open them (AUD-22).
class AppInfoScreen extends ConsumerWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfoAsync = ref.watch(appInfoNotifierProvider);
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
                child: appInfoAsync.when(
                  data: (info) => ListView(
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
                      Text(
                        'Version ${info.appVersion} (${info.buildNumber})',
                        textAlign: TextAlign.center,
                        style: AppTypography.mono(
                          textTheme.bodyMedium?.copyWith(color: t.textMuted),
                        ),
                      ),
                      const SizedBox(height: 28),
                      GroupedCard(
                        children: [
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
                          // The backend hands a URL, not an in-app page, so
                          // this opens out like the two above.
                          if (info.openSourceLicensesUrl case final url?)
                            _LinkRow(
                              title: 'Open-source licenses',
                              icon: Icons.open_in_new_rounded,
                              onTap: () => _open(ref, url),
                            ),
                          if (info.supportEmail case final email?)
                            _LinkRow(
                              title: 'Contact support',
                              subtitle: email,
                              icon: Icons.mail_outline_rounded,
                              onTap: () => _open(ref, 'mailto:$email'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Jenkins and GitHub calls go straight from this '
                        'device to your servers.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: ConnectionErrorView(
                      message: describeError(error),
                      onRetry: () =>
                          ref.read(appInfoNotifierProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
