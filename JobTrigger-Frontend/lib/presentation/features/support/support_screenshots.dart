import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/support/support_screenshot.dart';

/// A file the user chose, not yet read: the size check happens first so an
/// oversized file is never loaded into memory. [read] is a provider seam so
/// widget tests can supply bytes without a real picker.
class PickedSupportScreenshot {
  const PickedSupportScreenshot({
    required this.name,
    required this.sizeBytes,
    required this.read,
  });

  final String name;
  final int sizeBytes;
  final Future<Uint8List> Function() read;
}

typedef SupportScreenshotPicker = Future<PickedSupportScreenshot?> Function();

/// Gallery/files only — in-app camera capture would need a new package that
/// the owner has not approved. Plain Riverpod provider (no generator needed).
final supportScreenshotPickerProvider = Provider<SupportScreenshotPicker>(
  (ref) => () async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Choose a screenshot',
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (picked == null) return null;
    return PickedSupportScreenshot(
      name: picked.name,
      sizeBytes: await picked.length() ?? 0,
      read: picked.readAsBytes,
    );
  },
);

/// The current draft's screenshots. Bytes are held only for this one form and
/// are cleared after a successful send (or by "Remove"). The validation lives
/// here, not in the widget's `build`.
class SupportScreenshotsNotifier extends Notifier<List<SupportScreenshot>> {
  @override
  List<SupportScreenshot> build() => const [];

  /// Adds one file, or returns the reason it was refused. A cancelled picker
  /// returns `null` and leaves the draft untouched.
  Future<String?> add() async {
    if (state.length >= maxSupportScreenshots) {
      return 'Attach at most $maxSupportScreenshots screenshots.';
    }
    final picked = await ref.read(supportScreenshotPickerProvider)();
    if (picked == null) return null;
    if (picked.sizeBytes > maxSupportScreenshotBytes) {
      return 'Each screenshot must be under 5 MB.';
    }
    try {
      final bytes = await picked.read();
      final screenshot = SupportScreenshot(name: picked.name, bytes: bytes);
      final error = supportScreenshotError(screenshot);
      if (error != null) return error;
      state = [...state, screenshot];
      return null;
    } catch (_) {
      return 'That screenshot could not be read.';
    }
  }

  void remove(int index) {
    if (index < 0 || index >= state.length) return;
    state = [...state.sublist(0, index), ...state.sublist(index + 1)];
  }

  void clear() => state = const [];
}

final supportScreenshotsProvider =
    NotifierProvider<SupportScreenshotsNotifier, List<SupportScreenshot>>(
      SupportScreenshotsNotifier.new,
    );
