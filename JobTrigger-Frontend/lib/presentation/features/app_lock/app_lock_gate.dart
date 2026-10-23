import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import 'app_lock_notifier.dart';

/// US-JX-21: wraps the whole app. Covers it while the lock settings load,
/// while it's locked, and while it's in the app switcher; forwards
/// lifecycle changes to [AppLockNotifier].
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (lifecycle) => ref
          .read(appLockNotifierProvider.notifier)
          .onLifecycleChanged(lifecycle),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockNotifierProvider);
    final covered = !lock.loaded || lock.locked || lock.obscured;
    return Stack(
      children: [
        // Kept mounted so navigation survives a lock, but unreadable and
        // unreachable (including by screen readers) while covered.
        ExcludeSemantics(
          excluding: covered,
          child: AbsorbPointer(absorbing: covered, child: widget.child),
        ),
        if (covered)
          Positioned.fill(child: AppLockView(showUnlock: lock.locked)),
      ],
    );
  }
}

/// The full-screen cover (`UI-UX/screens/04-app-lock`): the lock mark and
/// an Unlock button when locked; just the mark and title as the privacy
/// screen the app switcher sees. Nothing from the app shows through (AUD-54).
///
/// One Unlock button rather than separate biometric and passcode ones: the
/// OS prompt already offers the passcode as its fallback, and naming one
/// biometric would be wrong on a device that has the other.
class AppLockView extends ConsumerWidget {
  const AppLockView({super.key, required this.showUnlock});

  final bool showUnlock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final t = AppTokens.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: ColoredBox(
          // The opaque fill is the privacy guarantee; the blur is only
          // there for the moment it fades in.
          color: t.background,
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ExcludeSemantics(
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: t.card,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: t.cardBorder),
                              ),
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 38,
                                color: t.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'JobTrigger is locked',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              fontSize: 26,
                            ),
                          ),
                          if (showUnlock) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Unlock with Face ID, your fingerprint or the '
                              'device passcode to see your servers and builds.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: t.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showUnlock)
                      FilledButton.icon(
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Unlock'),
                        onPressed: () =>
                            ref.read(appLockNotifierProvider.notifier).unlock(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
