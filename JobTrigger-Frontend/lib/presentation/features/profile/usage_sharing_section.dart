import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_consent_notifier.dart';
import '../../common_widgets/grouped_card.dart';

/// P20-76: Profile → Privacy → "Share anonymous usage". On by default;
/// the subtitle says exactly what is and isn't sent.
class UsageSharingSection extends ConsumerWidget {
  const UsageSharingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(analyticsConsentNotifierProvider).value ?? true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GroupHeader(title: 'Privacy'),
        GroupedCard(
          children: [
            SwitchListTile(
              key: const Key('share_usage_switch'),
              title: const Text('Share anonymous usage'),
              subtitle: const Text(
                'Which tools and features are used, to decide what to build '
                'next. Never your email, servers, jobs or tokens.',
              ),
              value: allowed,
              onChanged: (value) => ref
                  .read(analyticsConsentNotifierProvider.notifier)
                  .setAllowed(value),
            ),
          ],
        ),
      ],
    );
  }
}
