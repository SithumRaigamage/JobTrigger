import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../domain/credential/jenkins_url.dart';
import '../../../domain/credential/pair_link.dart';
import '../../common_widgets/responsive_center.dart';
import '../../navigation/app_routes.dart';
import '../settings/server_edit_bottom_sheet.dart';

/// Where a pairing QR lands (`NR-03`): `jobtrigger://app/pair?url=…&name=…`
/// opens this, shows what the code contains, and continues into the normal
/// add-server form with those fields filled in.
///
/// Janky codes are refused with a way to Settings rather than opening an
/// empty form. The token is never part of the code, so it's typed here, and
/// the sheet's usual validation, plan gate and save path apply unchanged.
class PairScreen extends ConsumerWidget {
  const PairScreen({super.key, this.query = const {}});

  /// The deep link's query parameters.
  final Map<String, String> query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final link = PairLink.fromQuery(query);
    final urlProblem = link == null ? null : jenkinsUrlProblem(link.jenkinsURL);

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 4, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Pair a server', style: textTheme.titleLarge),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (link == null)
                const _Message(
                  title: 'That code didn’t include a server',
                  message:
                      'Scan the code on the JobTrigger website again, or add '
                      'the server in Settings.',
                )
              else if (urlProblem != null)
                _Message(
                  title: 'That server address can’t be used',
                  message: urlProblem,
                )
              else ...[
                DecoratedBox(
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
                        Text(link.serverName, style: textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _Detail(label: 'Address', value: link.jenkinsURL),
                        if (link.username.isNotEmpty)
                          _Detail(label: 'Username', value: link.username),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Next you’ll enter the API token for this server. It isn’t '
                  'in the code, so a photo of the screen can’t leak it.',
                  style: textTheme.bodySmall?.copyWith(color: t.textMuted),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => _add(context, link),
                  child: const Text('Add this server'),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.settings),
                child: const Text('Go to Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the normal add-server sheet with the code's values; saving is the
  /// sheet's own path (validation, plan limit, backend), not a second one.
  Future<void> _add(BuildContext context, PairLink link) async {
    await showServerEditBottomSheet(
      context,
      prefillName: link.serverName,
      prefillURL: link.jenkinsURL,
      prefillUsername: link.username,
    );
    if (context.mounted) context.go(AppRoutes.home);
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(color: t.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodySmall?.copyWith(
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(color: t.textMuted),
          ),
        ],
      ),
    );
  }
}
