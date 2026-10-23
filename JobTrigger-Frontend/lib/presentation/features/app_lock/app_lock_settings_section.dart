import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/app_lock/app_lock_settings.dart';
import '../../common_widgets/grouped_card.dart';
import '../../common_widgets/toast_controller.dart';
import 'app_lock_notifier.dart';

/// US-JX-21: the biometric app lock's settings — on the profile since the
/// P14 redesign (`UI-UX/screens/10-profile`), where the design keeps the
/// account's security together.
class AppLockSettingsSection extends ConsumerWidget {
  const AppLockSettingsSection({super.key});

  static String _timeoutLabel(Duration timeout) => switch (timeout.inMinutes) {
    0 => 'Immediately',
    1 => 'After 1 minute',
    final minutes => 'After $minutes minutes',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(
      appLockNotifierProvider.select((lock) => lock.settings),
    );
    final notifier = ref.read(appLockNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GroupHeader(title: 'Security'),
        GroupedCard(
          children: [
            SwitchListTile(
              title: const Text('App lock'),
              subtitle: const Text(
                'Face ID, fingerprint or the device passcode to open the app',
              ),
              value: settings.enabled,
              onChanged: (value) async {
                final change = await notifier.setEnabled(value);
                if (change == LockChange.noDeviceSecurity) {
                  ref
                      .read(toastControllerProvider)
                      .show(
                        type: ToastType.warning,
                        title: "Can't turn on app lock",
                        message:
                            'Set up a passcode, fingerprint, or face unlock on '
                            'your phone first.',
                      );
                }
              },
            ),
            if (settings.enabled) ...[
              ListTile(
                title: const Text('Lock after leaving the app'),
                trailing: DropdownButton<Duration>(
                  value: settings.timeout,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final timeout in AppLockSettings.timeouts)
                      DropdownMenuItem(
                        value: timeout,
                        child: Text(_timeoutLabel(timeout)),
                      ),
                  ],
                  onChanged: (timeout) {
                    if (timeout != null) notifier.setTimeout(timeout);
                  },
                ),
              ),
              SwitchListTile(
                title: const Text('Confirm before triggering'),
                subtitle: const Text(
                  'Ask again to trigger, cancel, approve or replay builds, and to '
                  'change nodes and jobs',
                ),
                value: settings.requireForSensitive,
                onChanged: notifier.setRequireForSensitive,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
