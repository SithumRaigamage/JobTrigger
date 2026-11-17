import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/link_launcher.dart';
import 'toast_controller.dart';

/// Opens [uri] outside the app, and says so when nothing can (AUD-22)
/// instead of silently doing nothing.
Future<void> openExternalLink(WidgetRef ref, Uri uri) async {
  // Read before the await: the widget may be gone when it returns.
  final launch = ref.read(linkLauncherProvider);
  final toast = ref.read(toastControllerProvider);
  if (await launch(uri)) return;
  toast.show(
    type: ToastType.error,
    title: "Couldn't open link",
    message: uri.scheme == 'mailto'
        ? 'No email app is set up. Write to ${uri.path}.'
        : 'No app on this device can open ${uri.host}.',
  );
}
