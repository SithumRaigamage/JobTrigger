/// A local file chosen for a `FileParameterDefinition` (US-JX-02), uploaded
/// as one part of a `multipart/form-data` trigger. Plain Dart — the picker
/// itself lives in the presentation layer.
class ParameterFile {
  const ParameterFile({
    required this.fileName,
    required this.path,
    required this.sizeBytes,
  });

  final String fileName;

  /// Absolute path on this device. The app keeps no copy of the file.
  final String path;
  final int sizeBytes;
}

/// Files above this are refused before upload (US-JX-02): a phone upload of
/// something bigger is almost certainly a mistake, and it would hold the
/// trigger request open for minutes on a mobile connection.
const maxParameterFileBytes = 50 * 1024 * 1024;

/// Human-readable size, e.g. `1.4 MB`.
String formatFileSize(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return unit == 0 ? '$bytes B' : '${size.toStringAsFixed(1)} ${units[unit]}';
}
