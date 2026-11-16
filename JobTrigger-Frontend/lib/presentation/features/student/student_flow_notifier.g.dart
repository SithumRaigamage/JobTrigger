// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_flow_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Phase 21 (SP-41): the logic of the verify flow. Widgets only render
/// [StudentFlowState] and call these methods.

@ProviderFor(StudentFlowNotifier)
final studentFlowNotifierProvider = StudentFlowNotifierProvider._();

/// Phase 21 (SP-41): the logic of the verify flow. Widgets only render
/// [StudentFlowState] and call these methods.
final class StudentFlowNotifierProvider
    extends $NotifierProvider<StudentFlowNotifier, StudentFlowState> {
  /// Phase 21 (SP-41): the logic of the verify flow. Widgets only render
  /// [StudentFlowState] and call these methods.
  StudentFlowNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studentFlowNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$studentFlowNotifierHash();

  @$internal
  @override
  StudentFlowNotifier create() => StudentFlowNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StudentFlowState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StudentFlowState>(value),
    );
  }
}

String _$studentFlowNotifierHash() =>
    r'06c86a3f65b6ff3f7eb1a2f42f42badf128f8a57';

/// Phase 21 (SP-41): the logic of the verify flow. Widgets only render
/// [StudentFlowState] and call these methods.

abstract class _$StudentFlowNotifier extends $Notifier<StudentFlowState> {
  StudentFlowState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StudentFlowState, StudentFlowState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StudentFlowState, StudentFlowState>,
              StudentFlowState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
