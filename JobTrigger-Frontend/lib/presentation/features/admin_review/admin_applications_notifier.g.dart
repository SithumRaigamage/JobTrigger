// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_applications_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-STU-03: the chosen status filter on the applications screen.

@ProviderFor(AdminFilterNotifier)
final adminFilterNotifierProvider = AdminFilterNotifierProvider._();

/// US-STU-03: the chosen status filter on the applications screen.
final class AdminFilterNotifierProvider
    extends $NotifierProvider<AdminFilterNotifier, AdminStatusFilter> {
  /// US-STU-03: the chosen status filter on the applications screen.
  AdminFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminFilterNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminFilterNotifierHash();

  @$internal
  @override
  AdminFilterNotifier create() => AdminFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminStatusFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminStatusFilter>(value),
    );
  }
}

String _$adminFilterNotifierHash() =>
    r'5f33adaed68fe245ae6aff48f2697d705db1cf29';

/// US-STU-03: the chosen status filter on the applications screen.

abstract class _$AdminFilterNotifier extends $Notifier<AdminStatusFilter> {
  AdminStatusFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AdminStatusFilter, AdminStatusFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AdminStatusFilter, AdminStatusFilter>,
              AdminStatusFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// US-STU-02/03: the applications for one filter, newest first (the
/// backend's order). A failure is shown with a retry.

@ProviderFor(AdminApplicationsNotifier)
final adminApplicationsNotifierProvider = AdminApplicationsNotifierFamily._();

/// US-STU-02/03: the applications for one filter, newest first (the
/// backend's order). A failure is shown with a retry.
final class AdminApplicationsNotifierProvider
    extends
        $AsyncNotifierProvider<
          AdminApplicationsNotifier,
          List<AdminStudentApplication>
        > {
  /// US-STU-02/03: the applications for one filter, newest first (the
  /// backend's order). A failure is shown with a retry.
  AdminApplicationsNotifierProvider._({
    required AdminApplicationsNotifierFamily super.from,
    required AdminStatusFilter super.argument,
  }) : super(
         retry: null,
         name: r'adminApplicationsNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminApplicationsNotifierHash();

  @override
  String toString() {
    return r'adminApplicationsNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AdminApplicationsNotifier create() => AdminApplicationsNotifier();

  @override
  bool operator ==(Object other) {
    return other is AdminApplicationsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminApplicationsNotifierHash() =>
    r'af943ed88bb73889654013923ee967e7019d93b4';

/// US-STU-02/03: the applications for one filter, newest first (the
/// backend's order). A failure is shown with a retry.

final class AdminApplicationsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AdminApplicationsNotifier,
          AsyncValue<List<AdminStudentApplication>>,
          List<AdminStudentApplication>,
          FutureOr<List<AdminStudentApplication>>,
          AdminStatusFilter
        > {
  AdminApplicationsNotifierFamily._()
    : super(
        retry: null,
        name: r'adminApplicationsNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-STU-02/03: the applications for one filter, newest first (the
  /// backend's order). A failure is shown with a retry.

  AdminApplicationsNotifierProvider call(AdminStatusFilter filter) =>
      AdminApplicationsNotifierProvider._(argument: filter, from: this);

  @override
  String toString() => r'adminApplicationsNotifierProvider';
}

/// US-STU-02/03: the applications for one filter, newest first (the
/// backend's order). A failure is shown with a retry.

abstract class _$AdminApplicationsNotifier
    extends $AsyncNotifier<List<AdminStudentApplication>> {
  late final _$args = ref.$arg as AdminStatusFilter;
  AdminStatusFilter get filter => _$args;

  FutureOr<List<AdminStudentApplication>> build(AdminStatusFilter filter);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<AdminStudentApplication>>,
              List<AdminStudentApplication>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<AdminStudentApplication>>,
                List<AdminStudentApplication>
              >,
              AsyncValue<List<AdminStudentApplication>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
