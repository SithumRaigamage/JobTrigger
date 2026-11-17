import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/no_retry.dart';
import '../../../core/platform/package_info_provider.dart';
import '../../../domain/onboarding/whats_new.dart';
import 'whats_new_sheet.dart';

part 'whats_new_gate.g.dart';

/// PI-10 / IMP-65: the app version whose notes the user last saw. Device
/// level, not user-scoped: the sheet announces an update, not an account.
const whatsNewSeenVersionKey = 'whats_new_seen_version';

/// Package info for the gate. Separate from [packageInfoProvider] so a host
/// without the plugin (widget tests, unusual platforms) fails once: no
/// retry timer is left running behind the screen.
@Riverpod(retry: noRetry)
Future<PackageInfo> whatsNewPackageInfo(Ref ref) => PackageInfo.fromPlatform();

/// Shows the "What's new" sheet once after an update, then remembers that
/// version so it does not reappear on every launch.
///
/// Sits inside `MainScaffold` so it runs once the app is signed in and the
/// first frame is up. Every failure here (no package info on a test host,
/// unreadable prefs) is swallowed: release notes are a nicety, never a
/// reason to block the app.
class WhatsNewGate extends ConsumerStatefulWidget {
  const WhatsNewGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WhatsNewGate> createState() => _WhatsNewGateState();
}

class _WhatsNewGateState extends ConsumerState<WhatsNewGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (_checked || !mounted) return;
    _checked = true;

    final String version;
    try {
      version = (await ref.read(whatsNewPackageInfoProvider.future)).version;
    } on Object {
      return; // No package info (widget tests, unusual platforms).
    }
    if (!mounted || version.isEmpty) return;
    final release = whatsNewFor(version);
    if (release == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      if (prefs.getString(whatsNewSeenVersionKey) == version) return;

      await showWhatsNewSheet(context, version: version);
      await prefs.setString(whatsNewSeenVersionKey, version);
    } on Object {
      // Release notes are a nicety: a storage failure must not break Home.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
