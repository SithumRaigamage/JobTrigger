import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'toast_controller.dart';

/// Ported from `Shared/Components/ToastView.swift`.
class ToastView extends StatelessWidget {
  const ToastView({super.key, required this.message, required this.onDismiss});

  final ToastMessage message;
  final VoidCallback onDismiss;

  static const _iconByType = {
    ToastType.success: Icons.check_circle,
    ToastType.error: Icons.cancel,
    ToastType.warning: Icons.warning,
    ToastType.info: Icons.info,
  };

  static const _colorByType = {
    ToastType.success: Colors.green,
    ToastType.error: Colors.red,
    ToastType.warning: Colors.orange,
    ToastType.info: Colors.blue,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colorByType[message.type]!;
    return GestureDetector(
      onTap: onDismiss,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(_iconByType[message.type], size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                tooltip: 'Dismiss',
                onPressed: onDismiss,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ported from `Shared/Components/NotificationModifier.swift`. Wrap the app
/// (e.g. in `MaterialApp.builder`) so a toast can be shown from anywhere via
/// `toastControllerProvider`.
class ToastOverlay extends ConsumerWidget {
  const ToastOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(currentToastProvider);
    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (widget, animation) => SlideTransition(
              position: Tween(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: widget),
            ),
            child: message == null
                ? const SizedBox.shrink()
                : ToastView(
                    key: ValueKey(message),
                    message: message,
                    onDismiss: () =>
                        ref.read(toastControllerProvider).dismiss(),
                  ),
          ),
        ),
      ],
    );
  }
}
