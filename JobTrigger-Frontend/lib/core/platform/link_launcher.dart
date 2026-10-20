import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'link_launcher.g.dart';

/// Opens a URL in another app. True if something handled it.
typedef LinkLauncher = Future<bool> Function(Uri uri);

/// Behind a provider so tests can substitute it.
@Riverpod(keepAlive: true)
LinkLauncher linkLauncher(Ref ref) => (uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    return false; // No handler (PlatformException) or a malformed URL.
  }
};
