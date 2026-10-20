// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_log_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Streams a build's console via Jenkins' progressive-text API, family-keyed
/// by the build's absolute URL (US-LOG-01, rewritten for US-JX-07).
///
/// Each chunk is decoded exactly once by a [ConsoleDecoder], which carries
/// partial lines, escapes, and style across chunks. That replaces
/// re-sanitizing and re-splitting the whole log every second (AUD-12). A
/// failed poll keeps what's on screen and retries with backoff (AUD-13).
/// Timers are cancelled in `ref.onDispose`, the same leak discipline as
/// `BuildStatusPollingNotifier` (P5-06).

@ProviderFor(BuildLogNotifier)
final buildLogNotifierProvider = BuildLogNotifierFamily._();

/// Streams a build's console via Jenkins' progressive-text API, family-keyed
/// by the build's absolute URL (US-LOG-01, rewritten for US-JX-07).
///
/// Each chunk is decoded exactly once by a [ConsoleDecoder], which carries
/// partial lines, escapes, and style across chunks. That replaces
/// re-sanitizing and re-splitting the whole log every second (AUD-12). A
/// failed poll keeps what's on screen and retries with backoff (AUD-13).
/// Timers are cancelled in `ref.onDispose`, the same leak discipline as
/// `BuildStatusPollingNotifier` (P5-06).
final class BuildLogNotifierProvider
    extends $AsyncNotifierProvider<BuildLogNotifier, ConsoleState> {
  /// Streams a build's console via Jenkins' progressive-text API, family-keyed
  /// by the build's absolute URL (US-LOG-01, rewritten for US-JX-07).
  ///
  /// Each chunk is decoded exactly once by a [ConsoleDecoder], which carries
  /// partial lines, escapes, and style across chunks. That replaces
  /// re-sanitizing and re-splitting the whole log every second (AUD-12). A
  /// failed poll keeps what's on screen and retries with backoff (AUD-13).
  /// Timers are cancelled in `ref.onDispose`, the same leak discipline as
  /// `BuildStatusPollingNotifier` (P5-06).
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

String _$buildLogNotifierHash() => r'c830381b59935c6e5e61603775c8a820309b2e76';

/// Streams a build's console via Jenkins' progressive-text API, family-keyed
/// by the build's absolute URL (US-LOG-01, rewritten for US-JX-07).
///
/// Each chunk is decoded exactly once by a [ConsoleDecoder], which carries
/// partial lines, escapes, and style across chunks. That replaces
/// re-sanitizing and re-splitting the whole log every second (AUD-12). A
/// failed poll keeps what's on screen and retries with backoff (AUD-13).
/// Timers are cancelled in `ref.onDispose`, the same leak discipline as
/// `BuildStatusPollingNotifier` (P5-06).

final class BuildLogNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BuildLogNotifier,
          AsyncValue<ConsoleState>,
          ConsoleState,
          FutureOr<ConsoleState>,
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

  /// Streams a build's console via Jenkins' progressive-text API, family-keyed
  /// by the build's absolute URL (US-LOG-01, rewritten for US-JX-07).
  ///
  /// Each chunk is decoded exactly once by a [ConsoleDecoder], which carries
  /// partial lines, escapes, and style across chunks. That replaces
  /// re-sanitizing and re-splitting the whole log every second (AUD-12). A
  /// failed poll keeps what's on screen and retries with backoff (AUD-13).
  /// Timers are cancelled in `ref.onDispose`, the same leak discipline as
  /// `BuildStatusPollingNotifier` (P5-06).

  BuildLogNotifierProvider call(String buildUrl) =>
      BuildLogNotifierProvider._(argument: buildUrl, from: this);

  @override
  String toString() => r'buildLogNotifierProvider';
}

/// Streams a build's console via Jenkins' progressive-text API, family-keyed
/// by the build's absolute URL (US-LOG-01, rewritten for US-JX-07).
///
/// Each chunk is decoded exactly once by a [ConsoleDecoder], which carries
/// partial lines, escapes, and style across chunks. That replaces
/// re-sanitizing and re-splitting the whole log every second (AUD-12). A
/// failed poll keeps what's on screen and retries with backoff (AUD-13).
/// Timers are cancelled in `ref.onDispose`, the same leak discipline as
/// `BuildStatusPollingNotifier` (P5-06).

abstract class _$BuildLogNotifier extends $AsyncNotifier<ConsoleState> {
  late final _$args = ref.$arg as String;
  String get buildUrl => _$args;

  FutureOr<ConsoleState> build(String buildUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ConsoleState>, ConsoleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ConsoleState>, ConsoleState>,
              AsyncValue<ConsoleState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
