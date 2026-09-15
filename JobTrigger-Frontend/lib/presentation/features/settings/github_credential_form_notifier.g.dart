// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_credential_form_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Add/edit form submit state — mirrors `ServerFormNotifier`'s shape
/// exactly. Form field values are passed in at call time (owned by the
/// widget's `TextEditingController`s), not stored on the notifier.

@ProviderFor(GitHubCredentialFormNotifier)
final gitHubCredentialFormNotifierProvider =
    GitHubCredentialFormNotifierProvider._();

/// Add/edit form submit state — mirrors `ServerFormNotifier`'s shape
/// exactly. Form field values are passed in at call time (owned by the
/// widget's `TextEditingController`s), not stored on the notifier.
final class GitHubCredentialFormNotifierProvider
    extends $AsyncNotifierProvider<GitHubCredentialFormNotifier, void> {
  /// Add/edit form submit state — mirrors `ServerFormNotifier`'s shape
  /// exactly. Form field values are passed in at call time (owned by the
  /// widget's `TextEditingController`s), not stored on the notifier.
  GitHubCredentialFormNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gitHubCredentialFormNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gitHubCredentialFormNotifierHash();

  @$internal
  @override
  GitHubCredentialFormNotifier create() => GitHubCredentialFormNotifier();
}

String _$gitHubCredentialFormNotifierHash() =>
    r'e456a6a121fe82e43073dd74fb970641ec3daa01';

/// Add/edit form submit state — mirrors `ServerFormNotifier`'s shape
/// exactly. Form field values are passed in at call time (owned by the
/// widget's `TextEditingController`s), not stored on the notifier.

abstract class _$GitHubCredentialFormNotifier extends $AsyncNotifier<void> {
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
