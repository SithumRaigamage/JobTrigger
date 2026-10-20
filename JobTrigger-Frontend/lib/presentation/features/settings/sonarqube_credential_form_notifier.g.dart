// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_credential_form_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Add/edit form submit state — mirrors `GitHubCredentialFormNotifier`'s
/// shape exactly, including setting a newly-saved `isDefault: true`
/// credential as active immediately (not just flagging it and hoping a
/// future rehydrate picks it up — the fix `GitHubCredentialFormNotifier`
/// needed after the fact, built in here from day one). Form field values
/// are passed in at call time (owned by the widget's `TextEditingController`s),
/// not stored on the notifier.

@ProviderFor(SonarQubeCredentialFormNotifier)
final sonarQubeCredentialFormNotifierProvider =
    SonarQubeCredentialFormNotifierProvider._();

/// Add/edit form submit state — mirrors `GitHubCredentialFormNotifier`'s
/// shape exactly, including setting a newly-saved `isDefault: true`
/// credential as active immediately (not just flagging it and hoping a
/// future rehydrate picks it up — the fix `GitHubCredentialFormNotifier`
/// needed after the fact, built in here from day one). Form field values
/// are passed in at call time (owned by the widget's `TextEditingController`s),
/// not stored on the notifier.
final class SonarQubeCredentialFormNotifierProvider
    extends $AsyncNotifierProvider<SonarQubeCredentialFormNotifier, void> {
  /// Add/edit form submit state — mirrors `GitHubCredentialFormNotifier`'s
  /// shape exactly, including setting a newly-saved `isDefault: true`
  /// credential as active immediately (not just flagging it and hoping a
  /// future rehydrate picks it up — the fix `GitHubCredentialFormNotifier`
  /// needed after the fact, built in here from day one). Form field values
  /// are passed in at call time (owned by the widget's `TextEditingController`s),
  /// not stored on the notifier.
  SonarQubeCredentialFormNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sonarQubeCredentialFormNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sonarQubeCredentialFormNotifierHash();

  @$internal
  @override
  SonarQubeCredentialFormNotifier create() => SonarQubeCredentialFormNotifier();
}

String _$sonarQubeCredentialFormNotifierHash() =>
    r'1fe14cf87d5940be2f7b75bec8ba2ff9b36124b0';

/// Add/edit form submit state — mirrors `GitHubCredentialFormNotifier`'s
/// shape exactly, including setting a newly-saved `isDefault: true`
/// credential as active immediately (not just flagging it and hoping a
/// future rehydrate picks it up — the fix `GitHubCredentialFormNotifier`
/// needed after the fact, built in here from day one). Form field values
/// are passed in at call time (owned by the widget's `TextEditingController`s),
/// not stored on the notifier.

abstract class _$SonarQubeCredentialFormNotifier extends $AsyncNotifier<void> {
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
