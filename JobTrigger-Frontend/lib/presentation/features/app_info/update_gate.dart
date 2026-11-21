import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/platform/package_info_provider.dart';
import '../../../domain/app_info/app_info.dart';
import 'app_info_notifier.dart';

part 'update_gate.g.dart';

/// US-PROF-03: whether the backend's `minSupportedVersion` is newer than
/// the installed app. False while loading and on any failure: an outage
/// or an old backend never blocks the app.
@riverpod
Future<bool> updateRequired(Ref ref) async {
  try {
    final info = await ref.watch(appInfoNotifierProvider.future);
    final installed = await ref.watch(packageInfoProvider.future);
    return isUpdateRequired(installed.version, info.minSupportedVersion);
  } on Object {
    return false;
  }
}

/// US-PROF-03: covers the whole app with an "update required" screen
/// when this version is no longer supported. Nothing can be dismissed:
/// the backend asked for it on purpose (e.g. a broken release).
class UpdateRequiredGate extends ConsumerWidget {
  const UpdateRequiredGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final required = ref.watch(updateRequiredProvider).value ?? false;
    if (!required) return child;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      key: const Key('update_required'),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.system_update_rounded, size: 48),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(
                    'Update required',
                    style: textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This version of JobTrigger is no longer supported. Update '
                  'it from the App Store or Google Play to keep using it.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
