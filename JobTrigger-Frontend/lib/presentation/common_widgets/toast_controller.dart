import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'toast_controller.g.dart';

/// Ported from `Shared/Models/NotificationMessage.swift`'s `NotificationType`.
enum ToastType { success, error, warning, info }

/// Ported from `Shared/Models/NotificationMessage.swift`.
class ToastMessage {
  const ToastMessage({
    required this.type,
    required this.title,
    required this.message,
  });

  final ToastType type;
  final String title;
  final String message;
}

/// Holds the single currently-visible toast, watched by `ToastOverlay`.
/// Matches the old app's `NotificationManager`: only one toast is shown at a
/// time — a new one replaces whatever is showing rather than queuing.
@riverpod
class CurrentToast extends _$CurrentToast {
  @override
  ToastMessage? build() => null;

  void set(ToastMessage? message) => state = message;
}

/// Imperative API for showing toasts from anywhere (repositories, notifiers)
/// without needing a `BuildContext`. Ported from `NotificationManager.swift`,
/// including its 3.5s auto-dismiss timing.
class ToastController {
  ToastController(this._ref);

  final Ref _ref;
  Timer? _dismissTimer;

  static const _autoDismissDelay = Duration(milliseconds: 3500);

  void show({
    required ToastType type,
    required String title,
    required String message,
    bool autoDismiss = true,
  }) {
    _dismissTimer?.cancel();
    _ref
        .read(currentToastProvider.notifier)
        .set(ToastMessage(type: type, title: title, message: message));
    if (autoDismiss) {
      _dismissTimer = Timer(_autoDismissDelay, dismiss);
    }
  }

  void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _ref.read(currentToastProvider.notifier).set(null);
  }

  void cancelTimer() => _dismissTimer?.cancel();
}

@Riverpod(keepAlive: true)
ToastController toastController(Ref ref) {
  final controller = ToastController(ref);
  ref.onDispose(controller.cancelTimer);
  return controller;
}
