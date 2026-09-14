import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/error/error_message.dart';
import '../../common_widgets/connection_error_view.dart';
import '../../common_widgets/glass_surface.dart';
import '../../common_widgets/responsive_center.dart';
import 'app_info_notifier.dart';

/// Ported from `AppInfoView.swift` — see `docs/state-management.md`'s
/// `AppInfoNotifier` entry. Links open externally via `url_launcher`,
/// matching the old app's `openURL` environment action exactly.
class AppInfoScreen extends ConsumerWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfoAsync = ref.watch(appInfoNotifierProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('App Information')),
      body: ResponsiveCenter(
        child: appInfoAsync.when(
          data: (info) => ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + kToolbarHeight + 16,
              16,
              16,
            ),
            children: [
              Icon(
                Icons.apps,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'JobTrigger',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Version ${info.appVersion} (Build ${info.buildNumber})',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              GlassSurface.card(
                child: Column(
                  children: [
                    if (info.privacyPolicyUrl != null)
                      ListTile(
                        leading: const Icon(Icons.shield_outlined),
                        title: const Text('Privacy Policy'),
                        onTap: () => _open(info.privacyPolicyUrl!),
                      ),
                    if (info.termsOfServiceUrl != null)
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: const Text('Terms of Service'),
                        onTap: () => _open(info.termsOfServiceUrl!),
                      ),
                    if (info.openSourceLicensesUrl != null)
                      ListTile(
                        leading: const Icon(Icons.account_balance_outlined),
                        title: const Text('Open Source Licenses'),
                        onTap: () => _open(info.openSourceLicensesUrl!),
                      ),
                    if (info.supportEmail != null)
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Contact Support'),
                        subtitle: const Text(
                          'For feedback or issues, please contact our '
                          'support team.',
                        ),
                        onTap: () => _open('mailto:${info.supportEmail}'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: ConnectionErrorView(
              message: describeError(error),
              onRetry: () =>
                  ref.read(appInfoNotifierProvider.notifier).refresh(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
