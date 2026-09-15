// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_github_connection_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// "Test connection" (`US-GH-CRED-04`) state — mirrors
/// `TestConnectionNotifier`'s shape exactly. `state.value` is `null`
/// before the first test; otherwise the authenticated username on
/// success (unlike Jenkins' job count — GitHub's `/user` has no
/// equivalent count to show).

@ProviderFor(TestGitHubConnectionNotifier)
final testGitHubConnectionNotifierProvider =
    TestGitHubConnectionNotifierProvider._();

/// "Test connection" (`US-GH-CRED-04`) state — mirrors
/// `TestConnectionNotifier`'s shape exactly. `state.value` is `null`
/// before the first test; otherwise the authenticated username on
/// success (unlike Jenkins' job count — GitHub's `/user` has no
/// equivalent count to show).
final class TestGitHubConnectionNotifierProvider
    extends $AsyncNotifierProvider<TestGitHubConnectionNotifier, String?> {
  /// "Test connection" (`US-GH-CRED-04`) state — mirrors
  /// `TestConnectionNotifier`'s shape exactly. `state.value` is `null`
  /// before the first test; otherwise the authenticated username on
  /// success (unlike Jenkins' job count — GitHub's `/user` has no
  /// equivalent count to show).
  TestGitHubConnectionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'testGitHubConnectionNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$testGitHubConnectionNotifierHash();

  @$internal
  @override
  TestGitHubConnectionNotifier create() => TestGitHubConnectionNotifier();
}

String _$testGitHubConnectionNotifierHash() =>
    r'63e91c6c0ba4b8ac506e1133b5e8c2b3a0d2d7ce';

/// "Test connection" (`US-GH-CRED-04`) state — mirrors
/// `TestConnectionNotifier`'s shape exactly. `state.value` is `null`
/// before the first test; otherwise the authenticated username on
/// success (unlike Jenkins' job count — GitHub's `/user` has no
/// equivalent count to show).

abstract class _$TestGitHubConnectionNotifier extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
