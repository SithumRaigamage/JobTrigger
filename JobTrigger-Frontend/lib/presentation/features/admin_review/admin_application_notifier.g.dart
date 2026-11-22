// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_application_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-STU-02: one application and the approve/reject actions. The screen
/// asks for confirmation first and only renders this state.

@ProviderFor(AdminApplicationNotifier)
final adminApplicationNotifierProvider = AdminApplicationNotifierFamily._();

/// US-STU-02: one application and the approve/reject actions. The screen
/// asks for confirmation first and only renders this state.
final class AdminApplicationNotifierProvider
    extends
        $AsyncNotifierProvider<
          AdminApplicationNotifier,
          AdminApplicationState
        > {
  /// US-STU-02: one application and the approve/reject actions. The screen
  /// asks for confirmation first and only renders this state.
  AdminApplicationNotifierProvider._({
    required AdminApplicationNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'adminApplicationNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminApplicationNotifierHash();

  @override
  String toString() {
    return r'adminApplicationNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AdminApplicationNotifier create() => AdminApplicationNotifier();

  @override
  bool operator ==(Object other) {
    return other is AdminApplicationNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminApplicationNotifierHash() =>
    r'79bbd705cc801606c9a6df020eec23a0ca6e7e8a';

/// US-STU-02: one application and the approve/reject actions. The screen
/// asks for confirmation first and only renders this state.

final class AdminApplicationNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AdminApplicationNotifier,
          AsyncValue<AdminApplicationState>,
          AdminApplicationState,
          FutureOr<AdminApplicationState>,
          String
        > {
  AdminApplicationNotifierFamily._()
    : super(
        retry: null,
        name: r'adminApplicationNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-STU-02: one application and the approve/reject actions. The screen
  /// asks for confirmation first and only renders this state.

  AdminApplicationNotifierProvider call(String id) =>
      AdminApplicationNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'adminApplicationNotifierProvider';
}

/// US-STU-02: one application and the approve/reject actions. The screen
/// asks for confirmation first and only renders this state.

abstract class _$AdminApplicationNotifier
    extends $AsyncNotifier<AdminApplicationState> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<AdminApplicationState> build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<AdminApplicationState>, AdminApplicationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<AdminApplicationState>,
                AdminApplicationState
              >,
              AsyncValue<AdminApplicationState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// US-STU-02: the uploaded document, fetched with the admin's session and
/// held only in this provider's memory. Auto-disposed when the screen
/// closes, so the bytes go with it; nothing is written to disk.

@ProviderFor(adminDocument)
final adminDocumentProvider = AdminDocumentFamily._();

/// US-STU-02: the uploaded document, fetched with the admin's session and
/// held only in this provider's memory. Auto-disposed when the screen
/// closes, so the bytes go with it; nothing is written to disk.

final class AdminDocumentProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdminDocumentContent>,
          AdminDocumentContent,
          FutureOr<AdminDocumentContent>
        >
    with
        $FutureModifier<AdminDocumentContent>,
        $FutureProvider<AdminDocumentContent> {
  /// US-STU-02: the uploaded document, fetched with the admin's session and
  /// held only in this provider's memory. Auto-disposed when the screen
  /// closes, so the bytes go with it; nothing is written to disk.
  AdminDocumentProvider._({
    required AdminDocumentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'adminDocumentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adminDocumentHash();

  @override
  String toString() {
    return r'adminDocumentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AdminDocumentContent> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdminDocumentContent> create(Ref ref) {
    final argument = this.argument as String;
    return adminDocument(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminDocumentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminDocumentHash() => r'2753f7ff35b1c7dec7e1db63b8fdd0d1dcceb991';

/// US-STU-02: the uploaded document, fetched with the admin's session and
/// held only in this provider's memory. Auto-disposed when the screen
/// closes, so the bytes go with it; nothing is written to disk.

final class AdminDocumentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AdminDocumentContent>, String> {
  AdminDocumentFamily._()
    : super(
        retry: null,
        name: r'adminDocumentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-STU-02: the uploaded document, fetched with the admin's session and
  /// held only in this provider's memory. Auto-disposed when the screen
  /// closes, so the bytes go with it; nothing is written to disk.

  AdminDocumentProvider call(String id) =>
      AdminDocumentProvider._(argument: id, from: this);

  @override
  String toString() => r'adminDocumentProvider';
}
