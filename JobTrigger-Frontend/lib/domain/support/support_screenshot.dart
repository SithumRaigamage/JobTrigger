import 'dart:convert';
import 'dart:typed_data';

/// P31-02: a screenshot chosen from the gallery/files, held in memory only
/// until the report is submitted. The backend decides the final type and size;
/// these checks keep an obviously bad pick from ever leaving the phone.
class SupportScreenshot {
  const SupportScreenshot({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get sizeBytes => bytes.length;

  /// The same shape the website sends and the backend accepts: base64 in
  /// JSON, with no upload library and no path or token in the payload.
  Map<String, Object> toJson() => {'name': name, 'data': base64Encode(bytes)};
}

const int maxSupportScreenshots = 3;
const int maxSupportScreenshotBytes = 5 * 1024 * 1024;

/// Why this file cannot be sent, or `null` when it can. Magic bytes win over
/// the name: a renamed PDF is still rejected by the backend too.
String? supportScreenshotError(SupportScreenshot screenshot) {
  if (screenshot.sizeBytes == 0) return 'That screenshot is empty.';
  if (screenshot.sizeBytes > maxSupportScreenshotBytes) {
    return 'Each screenshot must be under 5 MB.';
  }
  final bytes = screenshot.bytes;
  final isPng =
      bytes.length > 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a;
  final isJpeg =
      bytes.length > 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff;
  if (!isPng && !isJpeg) return 'Screenshots must be JPG or PNG images.';
  return null;
}
