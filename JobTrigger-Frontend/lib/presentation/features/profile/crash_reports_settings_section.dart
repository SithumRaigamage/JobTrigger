import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error_reporting/crash_reporting.dart';
import '../../common_widgets/grouped_card.dart';
import '../../common_widgets/toast_controller.dart';

/// PE-26: the "Send crash reports" switch. On by default; the privacy policy
/// and the store privacy answers describe it as an opt-out. Turning it off
/// also clears reports that were waiting to be sent.
///
/// Debug and profile builds (not release) also get a "Send test crash
/// report", to check the whole path from the iPhone.
class CrashReportsSettingsSection extends ConsumerWidget {
  const CrashReportsSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(crashReportsEnabledProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GroupHeader(title: 'Privacy'),
        GroupedCard(
          children: [
            SwitchListTile(
              title: const Text('Send crash reports'),
              subtitle: const Text(
                'Helps fix problems. Reports never include passwords, tokens '
                'or what you type.',
              ),
              value: enabled,
              onChanged: (value) => ref
                  .read(crashReportsEnabledProvider.notifier)
                  .setEnabled(value),
            ),
            if (!kReleaseMode)
              ListTile(
                title: const Text('Send test crash report'),
                subtitle: const Text('Debug and profile builds only'),
                enabled: enabled,
                onTap: () async {
                  await ref.read(crashReportingProvider).sendTestReport();
                  ref
                      .read(toastControllerProvider)
                      .show(
                        type: ToastType.info,
                        title: 'Test report queued',
                        message: 'It is sent now, or when you are online.',
                      );
                },
              ),
          ],
        ),
      ],
    );
  }
}
