// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multibranch_notifiers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// US-JX-03: branch / pull request / tag classification for the jobs of
/// the multibranch project at [projectUrl], keyed by job `name`. Only
/// fetched while Home is showing that project.

@ProviderFor(branchKinds)
final branchKindsProvider = BranchKindsFamily._();

/// US-JX-03: branch / pull request / tag classification for the jobs of
/// the multibranch project at [projectUrl], keyed by job `name`. Only
/// fetched while Home is showing that project.

final class BranchKindsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, BranchKind>>,
          Map<String, BranchKind>,
          FutureOr<Map<String, BranchKind>>
        >
    with
        $FutureModifier<Map<String, BranchKind>>,
        $FutureProvider<Map<String, BranchKind>> {
  /// US-JX-03: branch / pull request / tag classification for the jobs of
  /// the multibranch project at [projectUrl], keyed by job `name`. Only
  /// fetched while Home is showing that project.
  BranchKindsProvider._({
    required BranchKindsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'branchKindsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$branchKindsHash();

  @override
  String toString() {
    return r'branchKindsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, BranchKind>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, BranchKind>> create(Ref ref) {
    final argument = this.argument as String;
    return branchKinds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BranchKindsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$branchKindsHash() => r'a5639fd695b52e1ad48ed1f517170e1ea2d11dc0';

/// US-JX-03: branch / pull request / tag classification for the jobs of
/// the multibranch project at [projectUrl], keyed by job `name`. Only
/// fetched while Home is showing that project.

final class BranchKindsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, BranchKind>>, String> {
  BranchKindsFamily._()
    : super(
        retry: null,
        name: r'branchKindsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-JX-03: branch / pull request / tag classification for the jobs of
  /// the multibranch project at [projectUrl], keyed by job `name`. Only
  /// fetched while Home is showing that project.

  BranchKindsProvider call(String projectUrl) =>
      BranchKindsProvider._(argument: projectUrl, from: this);

  @override
  String toString() => r'branchKindsProvider';
}

/// US-JX-03 "Scan now" for a multibranch project or organization folder.
/// State is `true` while a scan is being requested or running.
///
/// After the POST, polls the indexing log (`{projectUrl}indexing/`,
/// Jenkins' progressive-text contract, where `X-More-Data` means still
/// running) every [_pollEvery], then refreshes the project's contents and
/// branch groups. The timer is cancelled on dispose, the same leak
/// discipline as `BuildStatusPollingNotifier`.

@ProviderFor(MultibranchScanNotifier)
final multibranchScanNotifierProvider = MultibranchScanNotifierFamily._();

/// US-JX-03 "Scan now" for a multibranch project or organization folder.
/// State is `true` while a scan is being requested or running.
///
/// After the POST, polls the indexing log (`{projectUrl}indexing/`,
/// Jenkins' progressive-text contract, where `X-More-Data` means still
/// running) every [_pollEvery], then refreshes the project's contents and
/// branch groups. The timer is cancelled on dispose, the same leak
/// discipline as `BuildStatusPollingNotifier`.
final class MultibranchScanNotifierProvider
    extends $NotifierProvider<MultibranchScanNotifier, bool> {
  /// US-JX-03 "Scan now" for a multibranch project or organization folder.
  /// State is `true` while a scan is being requested or running.
  ///
  /// After the POST, polls the indexing log (`{projectUrl}indexing/`,
  /// Jenkins' progressive-text contract, where `X-More-Data` means still
  /// running) every [_pollEvery], then refreshes the project's contents and
  /// branch groups. The timer is cancelled on dispose, the same leak
  /// discipline as `BuildStatusPollingNotifier`.
  MultibranchScanNotifierProvider._({
    required MultibranchScanNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'multibranchScanNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$multibranchScanNotifierHash();

  @override
  String toString() {
    return r'multibranchScanNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MultibranchScanNotifier create() => MultibranchScanNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MultibranchScanNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$multibranchScanNotifierHash() =>
    r'f1d058102cac6868db612bbd4fe6ce34ab2bd386';

/// US-JX-03 "Scan now" for a multibranch project or organization folder.
/// State is `true` while a scan is being requested or running.
///
/// After the POST, polls the indexing log (`{projectUrl}indexing/`,
/// Jenkins' progressive-text contract, where `X-More-Data` means still
/// running) every [_pollEvery], then refreshes the project's contents and
/// branch groups. The timer is cancelled on dispose, the same leak
/// discipline as `BuildStatusPollingNotifier`.

final class MultibranchScanNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          MultibranchScanNotifier,
          bool,
          bool,
          bool,
          String
        > {
  MultibranchScanNotifierFamily._()
    : super(
        retry: null,
        name: r'multibranchScanNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// US-JX-03 "Scan now" for a multibranch project or organization folder.
  /// State is `true` while a scan is being requested or running.
  ///
  /// After the POST, polls the indexing log (`{projectUrl}indexing/`,
  /// Jenkins' progressive-text contract, where `X-More-Data` means still
  /// running) every [_pollEvery], then refreshes the project's contents and
  /// branch groups. The timer is cancelled on dispose, the same leak
  /// discipline as `BuildStatusPollingNotifier`.

  MultibranchScanNotifierProvider call(String projectUrl) =>
      MultibranchScanNotifierProvider._(argument: projectUrl, from: this);

  @override
  String toString() => r'multibranchScanNotifierProvider';
}

/// US-JX-03 "Scan now" for a multibranch project or organization folder.
/// State is `true` while a scan is being requested or running.
///
/// After the POST, polls the indexing log (`{projectUrl}indexing/`,
/// Jenkins' progressive-text contract, where `X-More-Data` means still
/// running) every [_pollEvery], then refreshes the project's contents and
/// branch groups. The timer is cancelled on dispose, the same leak
/// discipline as `BuildStatusPollingNotifier`.

abstract class _$MultibranchScanNotifier extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get projectUrl => _$args;

  bool build(String projectUrl);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
