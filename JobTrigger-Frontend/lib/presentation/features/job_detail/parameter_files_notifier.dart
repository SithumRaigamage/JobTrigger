import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/jenkins/parameter_file.dart';
import '../../common_widgets/toast_controller.dart';

part 'parameter_files_notifier.g.dart';

/// Opens the platform file picker and describes the chosen file, or returns
/// null if the user cancelled. A provider so tests can substitute it.
typedef ParameterFilePicker = Future<ParameterFile?> Function();

@riverpod
ParameterFilePicker parameterFilePicker(Ref ref) => () async {
  final picked = await FilePicker.pickFile(dialogTitle: 'Choose a file');
  final path = picked?.path;
  if (picked == null || path == null) return null;
  return ParameterFile(
    fileName: picked.name,
    path: path,
    sizeBytes: await picked.length() ?? 0,
  );
};

/// Why [ParameterFilesNotifier.pick] didn't attach a file.
enum FilePickOutcome { attached, cancelled, tooLarge }

/// Files chosen for a form's file parameters (US-JX-02), keyed by the same
/// form key as `ParameterEditsNotifier`. Holds paths only; the app never
/// copies or keeps the file itself.
@riverpod
class ParameterFilesNotifier extends _$ParameterFilesNotifier {
  @override
  Map<String, ParameterFile> build(String formKey) => const {};

  /// Picks a file for [parameterName], refusing anything over
  /// [maxParameterFileBytes] before it's ever uploaded.
  Future<FilePickOutcome> pick(String parameterName) async {
    final file = await ref.read(parameterFilePickerProvider)();
    if (file == null) return FilePickOutcome.cancelled;
    if (file.sizeBytes > maxParameterFileBytes) return FilePickOutcome.tooLarge;
    if (ref.mounted) state = {...state, parameterName: file};
    return FilePickOutcome.attached;
  }

  void remove(String parameterName) =>
      state = {...state}..remove(parameterName);
}

/// Picks a file for [parameterName] on form [formKey], telling the user if
/// it was refused for size. Shared by the trigger form and replay.
Future<void> pickParameterFile(
  WidgetRef ref,
  String formKey,
  String parameterName,
) async {
  final outcome = await ref
      .read(parameterFilesNotifierProvider(formKey).notifier)
      .pick(parameterName);
  if (outcome == FilePickOutcome.tooLarge) {
    ref
        .read(toastControllerProvider)
        .show(
          type: ToastType.warning,
          title: 'File too large',
          message:
              'Files over ${formatFileSize(maxParameterFileBytes)} can\'t be '
              'uploaded from the app.',
        );
  }
}
