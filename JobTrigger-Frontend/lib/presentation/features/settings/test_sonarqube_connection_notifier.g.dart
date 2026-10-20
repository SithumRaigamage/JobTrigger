// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_sonarqube_connection_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// "Test connection" (`US-SQ-CRED-04`) state — mirrors
/// `TestGitHubConnectionNotifier`'s shape: `state.value` is `null` before
/// the first test (idle) and `true` after a successful one. SonarQube's
/// `/api/authentication/validate` has nothing equivalent to GitHub's
/// `/user` to report back on success (no username), so `bool?` replaces
/// GitHub's `String?` as the idle/success sentinel — `AsyncValue<void>`
/// would have made "never tested" and "tested successfully" both render
/// as `AsyncData(null)`, indistinguishable to the UI.

@ProviderFor(TestSonarQubeConnectionNotifier)
final testSonarQubeConnectionNotifierProvider =
    TestSonarQubeConnectionNotifierProvider._();

/// "Test connection" (`US-SQ-CRED-04`) state — mirrors
/// `TestGitHubConnectionNotifier`'s shape: `state.value` is `null` before
/// the first test (idle) and `true` after a successful one. SonarQube's
/// `/api/authentication/validate` has nothing equivalent to GitHub's
/// `/user` to report back on success (no username), so `bool?` replaces
/// GitHub's `String?` as the idle/success sentinel — `AsyncValue<void>`
/// would have made "never tested" and "tested successfully" both render
/// as `AsyncData(null)`, indistinguishable to the UI.
final class TestSonarQubeConnectionNotifierProvider
    extends $AsyncNotifierProvider<TestSonarQubeConnectionNotifier, bool?> {
  /// "Test connection" (`US-SQ-CRED-04`) state — mirrors
  /// `TestGitHubConnectionNotifier`'s shape: `state.value` is `null` before
  /// the first test (idle) and `true` after a successful one. SonarQube's
  /// `/api/authentication/validate` has nothing equivalent to GitHub's
  /// `/user` to report back on success (no username), so `bool?` replaces
  /// GitHub's `String?` as the idle/success sentinel — `AsyncValue<void>`
  /// would have made "never tested" and "tested successfully" both render
  /// as `AsyncData(null)`, indistinguishable to the UI.
  TestSonarQubeConnectionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'testSonarQubeConnectionNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$testSonarQubeConnectionNotifierHash();

  @$internal
  @override
  TestSonarQubeConnectionNotifier create() => TestSonarQubeConnectionNotifier();
}

String _$testSonarQubeConnectionNotifierHash() =>
    r'a8406852534a944ea3901bda0c859855b9df6189';

/// "Test connection" (`US-SQ-CRED-04`) state — mirrors
/// `TestGitHubConnectionNotifier`'s shape: `state.value` is `null` before
/// the first test (idle) and `true` after a successful one. SonarQube's
/// `/api/authentication/validate` has nothing equivalent to GitHub's
/// `/user` to report back on success (no username), so `bool?` replaces
/// GitHub's `String?` as the idle/success sentinel — `AsyncValue<void>`
/// would have made "never tested" and "tested successfully" both render
/// as `AsyncData(null)`, indistinguishable to the UI.

abstract class _$TestSonarQubeConnectionNotifier extends $AsyncNotifier<bool?> {
  FutureOr<bool?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool?>, bool?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool?>, bool?>,
              AsyncValue<bool?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
