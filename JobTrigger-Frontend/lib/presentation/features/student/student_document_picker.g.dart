// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_document_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(studentDocumentPicker)
final studentDocumentPickerProvider = StudentDocumentPickerProvider._();

final class StudentDocumentPickerProvider
    extends
        $FunctionalProvider<
          StudentDocumentPicker,
          StudentDocumentPicker,
          StudentDocumentPicker
        >
    with $Provider<StudentDocumentPicker> {
  StudentDocumentPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studentDocumentPickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$studentDocumentPickerHash();

  @$internal
  @override
  $ProviderElement<StudentDocumentPicker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StudentDocumentPicker create(Ref ref) {
    return studentDocumentPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StudentDocumentPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StudentDocumentPicker>(value),
    );
  }
}

String _$studentDocumentPickerHash() =>
    r'09e3d81583211ed88b8992296c55d8401d5fc6a9';
