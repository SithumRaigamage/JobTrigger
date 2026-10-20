import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
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

/// The full-screen glass cover: an unlock button when locked, otherwise
/// just the privacy screen.
class AppLockView extends ConsumerWidget {
  const AppLockView({super.key, required this.showUnlock});

  final bool showUnlock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: ColoredBox(
          // The opaque fallback fill: the blur is decoration, not the
          // privacy guarantee.
          color: isDark
              ? AppColors.glassFallbackFillDark
              : AppColors.glassFallbackFillLight,
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 56,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'JobTrigger is locked',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (showUnlock) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Unlock'),
                      onPressed: () =>
                          ref.read(appLockNotifierProvider.notifier).unlock(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
