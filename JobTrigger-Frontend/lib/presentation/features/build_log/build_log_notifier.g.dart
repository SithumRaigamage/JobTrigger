// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_log_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Accumulates a build's console log via Jenkins' Progressive Text API,
/// family-keyed by the build's absolute URL. Polls ~1s between reads
/// (`docs/api-reference.md#polling-intervals`) — deliberately faster than
/// the old Swift app's fixed 3s (`BuildLogViewModel.setupTimer`); the docs
/// explicitly call for ~1s for this rewrite. Stops on its own once
/// `X-More-Data` is false. Timer always cancelled in `ref.onDispose`, same
/// leak discipline as `BuildStatusPollingNotifier` (P5-06).

@ProviderFor(BuildLogNotifier)
final buildLogNotifierProvider = BuildLogNotifierFamily._();

/// Accumulates a build's console log via Jenkins' Progressive Text API,
/// family-keyed by the build's absolute URL. Polls ~1s between reads
/// (`docs/api-reference.md#polling-intervals`) — deliberately faster than
/// the old Swift app's fixed 3s (`BuildLogViewModel.setupTimer`); the docs
/// explicitly call for ~1s for this rewrite. Stops on its own once
/// `X-More-Data` is false. Timer always cancelled in `ref.onDispose`, same
/// leak discipline as `BuildStatusPollingNotifier` (P5-06).
final class BuildLogNotifierProvider
    extends $AsyncNotifierProvider<BuildLogNotifier, String> {
  /// Accumulates a build's console log via Jenkins' Progressive Text API,
  /// family-keyed by the build's absolute URL. Polls ~1s between reads
  /// (`docs/api-reference.md#polling-intervals`) — deliberately faster than
  /// the old Swift app's fixed 3s (`BuildLogViewModel.setupTimer`); the docs
  /// explicitly call for ~1s for this rewrite. Stops on its own once
  /// `X-More-Data` is false. Timer always cancelled in `ref.onDispose`, same
  /// leak discipline as `BuildStatusPollingNotifier` (P5-06).
  BuildLogNotifierProvider._({
    required BuildLogNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'buildLogNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$buildLogNotifierHash();

  @override
  String toString() {
    return r'buildLogNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BuildLogNotifier create() => BuildLogNotifier();

  @override
  bool operator ==(Object other) {
    return other is BuildLogNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$buildLogNotifierHash() => r'a7eb053b8571e312a4c5e09893c261cda922f059';

/// Accumulates a build's console log via Jenkins' Progressive Text API,
/// family-keyed by the build's absolute URL. Polls ~1s between reads
/// (`docs/api-reference.md#polling-intervals`) — deliberately faster than
/// the old Swift app's fixed 3s (`BuildLogViewModel.setupTimer`); the docs
/// explicitly call for ~1s for this rewrite. Stops on its own once
/// `X-More-Data` is false. Timer always cancelled in `ref.onDispose`, same
/// leak discipline as `BuildStatusPollingNotifier` (P5-06).

final class BuildLogNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BuildLogNotifier,
          AsyncValue<String>,
          String,
          FutureOr<String>,
          String
        > {
  BuildLogNotifierFamily._()
    : super(
        retry: null,
        name: r'buildLogNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Accumulates a build's console log via Jenkins' Progressive Text API,
  /// family-keyed by the build's absolute URL. Polls ~1s between reads
  /// (`docs/api-reference.md#polling-intervals`) — deliberately faster than
  /// the old Swift app's fixed 3s (`BuildLogViewModel.setupTimer`); the docs
  /// explicitly call for ~1s for this rewrite. Stops on its own once
  /// `X-More-Data` is false. Timer always cancelled in `ref.onDispose`, same
  /// leak discipline as `BuildStatusPollingNotifier` (P5-06).

  BuildLogNotifierProvider call(String buildUrl) =>
      BuildLogNotifierProvider._(argument: buildUrl, from: this);

  @override
  String toString() => r'buildLogNotifierProvider';
}

/// Accumulates a build's console log via Jenkins' Progressive Text API,
/// family-keyed by the build's absolute URL. Polls ~1s between reads
/// (`docs/api-reference.md#polling-intervals`) — deliberately faster than
/// the old Swift app's fixed 3s (`BuildLogViewModel.setupTimer`); the docs
/// explicitly call for ~1s for this rewrite. Stops on its own once
/// `X-More-Data` is false. Timer always cancelled in `ref.onDispose`, same
/// leak discipline as `BuildStatusPollingNotifier` (P5-06).

abstract class _$BuildLogNotifier extends $AsyncNotifier<String> {
  late final _$args = ref.$arg as String;
  String get buildUrl => _$args;

  FutureOr<String> build(String buildUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
