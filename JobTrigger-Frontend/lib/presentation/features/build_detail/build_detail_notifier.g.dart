// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_detail_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-JX-14: one build in full, plus its two edits. Each edit re-reads
/// the build instead of assuming the result: `toggleLogKeep` *toggles*,
/// so a local flip could drift from the server.

@ProviderFor(BuildDetailNotifier)
final buildDetailNotifierProvider = BuildDetailNotifierFamily._();

/// US-JX-14: one build in full, plus its two edits. Each edit re-reads
/// the build instead of assuming the result: `toggleLogKeep` *toggles*,
/// so a local flip could drift from the server.
final class BuildDetailNotifierProvider
    extends $AsyncNotifierProvider<BuildDetailNotifier, JenkinsBuild> {
  /// US-JX-14: one build in full, plus its two edits. Each edit re-reads
  /// the build instead of assuming the result: `toggleLogKeep` *toggles*,
  /// so a local flip could drift from the server.
  BuildDetailNotifierProvider._({
    required BuildDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'buildDetailNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$buildDetailNotifierHash();

  @override
  String toString() {
    return r'buildDetailNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BuildDetailNotifier create() => BuildDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is BuildDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$buildDetailNotifierHash() =>
    r'0fa047df670496db18e9e5f4e26be86060ab31a7';

/// US-JX-14: one build in full, plus its two edits. Each edit re-reads
/// the build instead of assuming the result: `toggleLogKeep` *toggles*,
/// so a local flip could drift from the server.

final class BuildDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BuildDetailNotifier,
          AsyncValue<JenkinsBuild>,
          JenkinsBuild,
          FutureOr<JenkinsBuild>,
          String
        > {
  BuildDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'buildDetailNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-JX-14: one build in full, plus its two edits. Each edit re-reads
  /// the build instead of assuming the result: `toggleLogKeep` *toggles*,
  /// so a local flip could drift from the server.

  BuildDetailNotifierProvider call(String buildUrl) =>
      BuildDetailNotifierProvider._(argument: buildUrl, from: this);

  @override
  String toString() => r'buildDetailNotifierProvider';
}

/// US-JX-14: one build in full, plus its two edits. Each edit re-reads
/// the build instead of assuming the result: `toggleLogKeep` *toggles*,
/// so a local flip could drift from the server.

abstract class _$BuildDetailNotifier extends $AsyncNotifier<JenkinsBuild> {
  late final _$args = ref.$arg as String;
  String get buildUrl => _$args;

  FutureOr<JenkinsBuild> build(String buildUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<JenkinsBuild>, JenkinsBuild>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<JenkinsBuild>, JenkinsBuild>,
              AsyncValue<JenkinsBuild>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
