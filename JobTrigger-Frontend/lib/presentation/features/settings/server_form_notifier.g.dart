// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_form_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Add/edit form submit state — see `docs/state-management.md`'s "Feature:
/// settings / server management" section. Same shape as
/// `LoginNotifier`/`SignupNotifier`: form field values are passed in at
/// call time (owned by the widget's `TextEditingController`s), not stored
/// on the notifier.

@ProviderFor(ServerFormNotifier)
final serverFormNotifierProvider = ServerFormNotifierProvider._();

/// Add/edit form submit state — see `docs/state-management.md`'s "Feature:
/// settings / server management" section. Same shape as
/// `LoginNotifier`/`SignupNotifier`: form field values are passed in at
/// call time (owned by the widget's `TextEditingController`s), not stored
/// on the notifier.
final class ServerFormNotifierProvider
    extends $AsyncNotifierProvider<ServerFormNotifier, void> {
  /// Add/edit form submit state — see `docs/state-management.md`'s "Feature:
  /// settings / server management" section. Same shape as
  /// `LoginNotifier`/`SignupNotifier`: form field values are passed in at
  /// call time (owned by the widget's `TextEditingController`s), not stored
  /// on the notifier.
  ServerFormNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverFormNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverFormNotifierHash();

  @$internal
  @override
  ServerFormNotifier create() => ServerFormNotifier();
}

String _$serverFormNotifierHash() =>
    r'accdf5f06f379de754e0aa8d85b3a66c5506499b';

/// Add/edit form submit state — see `docs/state-management.md`'s "Feature:
/// settings / server management" section. Same shape as
/// `LoginNotifier`/`SignupNotifier`: form field values are passed in at
/// call time (owned by the widget's `TextEditingController`s), not stored
/// on the notifier.

abstract class _$ServerFormNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
