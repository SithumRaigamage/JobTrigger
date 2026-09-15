// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_connection_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// "Test connection" (P3-08) state — separate from `ServerFormNotifier`
/// since a user can test a candidate server's connection independently of
/// (and repeatedly before) actually saving it. `state.value` is `null`
/// before the first test; otherwise the job count on success, with the
/// failure surfaced as `AsyncError` like everywhere else.

@ProviderFor(TestConnectionNotifier)
final testConnectionNotifierProvider = TestConnectionNotifierProvider._();

/// "Test connection" (P3-08) state — separate from `ServerFormNotifier`
/// since a user can test a candidate server's connection independently of
/// (and repeatedly before) actually saving it. `state.value` is `null`
/// before the first test; otherwise the job count on success, with the
/// failure surfaced as `AsyncError` like everywhere else.
final class TestConnectionNotifierProvider
    extends $AsyncNotifierProvider<TestConnectionNotifier, int?> {
  /// "Test connection" (P3-08) state — separate from `ServerFormNotifier`
  /// since a user can test a candidate server's connection independently of
  /// (and repeatedly before) actually saving it. `state.value` is `null`
  /// before the first test; otherwise the job count on success, with the
  /// failure surfaced as `AsyncError` like everywhere else.
  TestConnectionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'testConnectionNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$testConnectionNotifierHash();

  @$internal
  @override
  TestConnectionNotifier create() => TestConnectionNotifier();
}

String _$testConnectionNotifierHash() =>
    r'd6ee1fc1bcdbba0be0b44801c438c25a90a5e647';

/// "Test connection" (P3-08) state — separate from `ServerFormNotifier`
/// since a user can test a candidate server's connection independently of
/// (and repeatedly before) actually saving it. `state.value` is `null`
/// before the first test; otherwise the job count on success, with the
/// failure surfaced as `AsyncError` like everywhere else.

abstract class _$TestConnectionNotifier extends $AsyncNotifier<int?> {
  FutureOr<int?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int?>, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int?>, int?>,
              AsyncValue<int?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
