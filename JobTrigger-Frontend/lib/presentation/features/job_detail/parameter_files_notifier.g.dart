// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parameter_files_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(parameterFilePicker)
final parameterFilePickerProvider = ParameterFilePickerProvider._();

final class ParameterFilePickerProvider
    extends
        $FunctionalProvider<
          ParameterFilePicker,
          ParameterFilePicker,
          ParameterFilePicker
        >
    with $Provider<ParameterFilePicker> {
  ParameterFilePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'parameterFilePickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$parameterFilePickerHash();

  @$internal
  @override
  $ProviderElement<ParameterFilePicker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ParameterFilePicker create(Ref ref) {
    return parameterFilePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ParameterFilePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ParameterFilePicker>(value),
    );
  }
}

String _$parameterFilePickerHash() =>
    r'87c14bb09cf526a58d7a0f5ef19c4725ecd15301';

/// Files chosen for a form's file parameters (US-JX-02), keyed by the same
/// form key as `ParameterEditsNotifier`. Holds paths only; the app never
/// copies or keeps the file itself.

@ProviderFor(ParameterFilesNotifier)
final parameterFilesNotifierProvider = ParameterFilesNotifierFamily._();

/// Files chosen for a form's file parameters (US-JX-02), keyed by the same
/// form key as `ParameterEditsNotifier`. Holds paths only; the app never
/// copies or keeps the file itself.
final class ParameterFilesNotifierProvider
    extends
        $NotifierProvider<ParameterFilesNotifier, Map<String, ParameterFile>> {
  /// Files chosen for a form's file parameters (US-JX-02), keyed by the same
  /// form key as `ParameterEditsNotifier`. Holds paths only; the app never
  /// copies or keeps the file itself.
  ParameterFilesNotifierProvider._({
    required ParameterFilesNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'parameterFilesNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$parameterFilesNotifierHash();

  @override
  String toString() {
    return r'parameterFilesNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ParameterFilesNotifier create() => ParameterFilesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, ParameterFile> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, ParameterFile>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ParameterFilesNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$parameterFilesNotifierHash() =>
    r'48b9a7ba6e9793d9cfd2f2ffeb70885be8dff6bb';

/// Files chosen for a form's file parameters (US-JX-02), keyed by the same
/// form key as `ParameterEditsNotifier`. Holds paths only; the app never
/// copies or keeps the file itself.

final class ParameterFilesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ParameterFilesNotifier,
          Map<String, ParameterFile>,
          Map<String, ParameterFile>,
          Map<String, ParameterFile>,
          String
        > {
  ParameterFilesNotifierFamily._()
    : super(
        retry: null,
        name: r'parameterFilesNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Files chosen for a form's file parameters (US-JX-02), keyed by the same
  /// form key as `ParameterEditsNotifier`. Holds paths only; the app never
  /// copies or keeps the file itself.

  ParameterFilesNotifierProvider call(String formKey) =>
      ParameterFilesNotifierProvider._(argument: formKey, from: this);

  @override
  String toString() => r'parameterFilesNotifierProvider';
}

/// Files chosen for a form's file parameters (US-JX-02), keyed by the same
/// form key as `ParameterEditsNotifier`. Holds paths only; the app never
/// copies or keeps the file itself.

abstract class _$ParameterFilesNotifier
    extends $Notifier<Map<String, ParameterFile>> {
  late final _$args = ref.$arg as String;
  String get formKey => _$args;

  Map<String, ParameterFile> build(String formKey);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<Map<String, ParameterFile>, Map<String, ParameterFile>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, ParameterFile>,
                Map<String, ParameterFile>
              >,
              Map<String, ParameterFile>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
