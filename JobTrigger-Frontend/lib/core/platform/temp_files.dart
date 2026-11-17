import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'temp_files.g.dart';

/// AUD-50: [name] reduced to a single, harmless path segment for writing
/// inside a temp folder. Names come from Jenkins (`artifacts[].fileName`),
/// so a hostile or compromised server, or a MITM on `http://`, could send
/// `../../shared_prefs/x.xml`. Keeps the last segment after `/` or `\`,
/// drops control characters, and falls back to [fallback] for nothing,
/// `.`, or `..`.
String safeFileName(String name, {String fallback = 'download'}) {
  final last = name.split(RegExp(r'[/\\]')).last;
  final cleaned = last.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
  return cleaned.isEmpty || cleaned == '.' || cleaned == '..'
      ? fallback
      : cleaned;
}

/// Where a file is written just long enough to share it (a full console
/// log, an artifact). A provider so tests can substitute it.
@riverpod
Future<Directory> tempDirectory(Ref ref) => getTemporaryDirectory();

/// Hands a file to the OS share sheet.
typedef FileSharer = Future<void> Function(String path, String subject);

/// A provider so tests can substitute it.
@riverpod
FileSharer fileSharer(Ref ref) =>
    (path, subject) => SharePlus.instance.share(
      ShareParams(files: [XFile(path)], subject: subject),
    );
