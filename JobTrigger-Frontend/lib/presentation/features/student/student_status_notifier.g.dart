// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_status_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Phase 21 (SP-42): the signed-in user's latest student application.
/// Loaded when the verification screen opens and after every step of the
/// flow. A failure is shown with a retry; it never affects the plan.

@ProviderFor(StudentStatusNotifier)
final studentStatusNotifierProvider = StudentStatusNotifierProvider._();

/// Phase 21 (SP-42): the signed-in user's latest student application.
/// Loaded when the verification screen opens and after every step of the
/// flow. A failure is shown with a retry; it never affects the plan.
final class StudentStatusNotifierProvider
    extends $AsyncNotifierProvider<StudentStatusNotifier, StudentApplication> {
  /// Phase 21 (SP-42): the signed-in user's latest student application.
  /// Loaded when the verification screen opens and after every step of the
  /// flow. A failure is shown with a retry; it never affects the plan.
  StudentStatusNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studentStatusNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$studentStatusNotifierHash();

  @$internal
  @override
  StudentStatusNotifier create() => StudentStatusNotifier();
}

String _$studentStatusNotifierHash() =>
    r'99846824060b8dd0de066ef7414522ba3509f890';

/// Phase 21 (SP-42): the signed-in user's latest student application.
/// Loaded when the verification screen opens and after every step of the
/// flow. A failure is shown with a retry; it never affects the plan.

abstract class _$StudentStatusNotifier
    extends $AsyncNotifier<StudentApplication> {
  FutureOr<StudentApplication> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<StudentApplication>, StudentApplication>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StudentApplication>, StudentApplication>,
              AsyncValue<StudentApplication>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
