import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'temp_files.g.dart';

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
